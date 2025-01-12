# Input bindings are passed in via param block.
param($Timer, $PSDocuments)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

$FileMaestro=$PSDocuments
$githubToken = Get-AzKeyVaultSecret -VaultName "PSFundamentals-KV" -Name "GitHubPAT" -AsPlainText
Import-Module PowerHTML -Verbose
$owner = $env:GitHubUser
$repo = $env:GitHubRepo
$branch = $env:GitHubBranch
$Date=$(get-date -Format MM/dd/yyyy)
$indexFilePath = "index.html"
$postFilePath="_posts\2024-02-10-file-maestro.html"

$commitMessage = "$Date update post#5"

$headers = @{
    Authorization = "Bearer $githubToken"
    Accept = "application/vnd.github.v3+json"
}

# Get the file SHA (to update existing post)
$postApiUrl = "https://api.github.com/repos/$owner/$repo/contents/$($postFilePath)?ref=$($branch)"
$response = Invoke-RestMethod -Uri $postApiUrl -Headers $headers -Method Get
$postSha = $response.sha

$recentArrivalsApiUrl = "https://api.github.com/repos/$owner/$repo/contents/$($recentArrivalsFilePath)?ref=$($branch)"
#Get post file content
$headers = @{
    Authorization = "Bearer $githubToken"
    Accept = "application/vnd.github.raw+json"
}
$response = Invoke-RestMethod -Uri $postApiUrl -Headers $headers -Method Get

$Synopsis="$($FileMaestro.id) by $($FileMaestro.CompanyName)"
$SynopsisNode = [HtmlAgilityPack.HtmlNode]::CreateNode("<dt>$Synopsis</dt>")
$FilesNode=[HtmlAgilityPack.HtmlNode]::CreateNode(" <dd>$($FileMaestro.FileCount) files</dd>")
#Update post content here
$response=$response -replace '<dd>\d{2}/\d{2}/\d{4}</dd>', "<dd>$Date</dd>"
$dataPointCount = ([regex]::Matches($response, '<div class="data-point"')).Count

#if($dataPointCount -lt 12){
    #just append at the bottom
    $matches = [regex]::Matches($response, '<li style="--x: \d+px; --y: \d+\.?\d*px;">.*?')
    $latestLi = $matches[$matches.Count - 1].Value
    $x=40+(($latestLi -split ':') -split ';')[1].Replace('px',"").Trim()
    $oldY=(($latestLi -split ':') -split ';')[3].Replace('px',"").Trim()
    $y=$($FileMaestro.FileCount)/100
    $dataValue=95
    $lineSegment = "<div class=`"line-segment`" style=`"--hypotenuse: 40; --angle:$($oldY-$y);`"></div>"
    $response=$response | ConvertFrom-Html

    $response.SelectNodes("//dt")[0].ParentNode.ReplaceChild($SynopsisNode,$response.SelectNodes("//dt")[0])
    $response.SelectNodes("//dd")[0].ParentNode.ReplaceChild($FilesNode,$response.SelectNodes("//dd")[0])
    $liNodes = $response.SelectNodes("//li")
    $lineSegmentNode = [HtmlAgilityPack.HtmlNode]::CreateNode($linesegment)
    $liNodes[-1].AppendChild($lineSegmentNode)
    $newEntry=@"
<li style="--x: $($x)px; --y: $($y)px;">
            <div class="data-point" data-value="$($dataValue)">
              <span class="tooltiptext">$($FileMaestro.FileCount)</span>
              <p>
                $(get-date -Format MMM-yy)
              </p>
            </div>
          </li>
"@
$newEntryNode = [HtmlAgilityPack.HtmlNode]::CreateNode($newEntry)
$liNodes[-1].ParentNode.AppendChild($newEntryNode)
#}
if ($dataPointCount -eq 12) {
    <# remove 1st #>
    $liNodes.RemoveAt(0)
}

#commit changes
$UpdatedPostBase64=[Convert]::ToBase64String($OutputEncoding.GetBytes($response.OuterHtml))
# Create request body
$body = @{
    message = $commitMessage
    content = $UpdatedPostBase64
    sha     = $postSha 
    branch  = $branch
}
$jsonBody = $body | ConvertTo-Json
# Commit file using GitHub API
$headers = @{
    Authorization = "Bearer $githubToken"
    Accept = "application/vnd.github+json"
    'Content-Type'='application/json'
}
$commitUrl = "https://api.github.com/repos/$owner/$repo/contents/$postFilePath"
$response = Invoke-WebRequest -Uri $commitUrl -Headers $headers -Method Put -Body $jsonBody

#fetch index page
#update it
#commit changes