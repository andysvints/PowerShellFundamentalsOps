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

$HasProjectUrl=$PSDocuments | ConvertTo-Json -Depth 10

$githubToken = Get-AzKeyVaultSecret -VaultName "PSFundamentals-KV" -Name "GitHubPAT" -AsPlainText

$owner = $env:GitHubUser
$repo = $env:GitHubRepo
$branch = $env:GitHubBranch
$Date=$(get-date -Format MM/dd/yyyy)
$indexFilePath = "index.html"
$postFilePath="_posts/2024-02-13-Discoverability.html"
$recentArrivalsFilePath="_posts/2024-02-14-recent-arrivals.html"
$commitMessage = "$Date update post#2"

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
$recentArrivalsResponse = Invoke-RestMethod -Uri $recentArrivalsApiUrl -Headers $headers -Method Get
$recentArrivalsResponse=$recentArrivalsResponse | ConvertFrom-Html

$recentArrivalsSynopsisNode = $recentArrivalsResponse.SelectNodes("//dl[@class='synopsis']")[0]

$recentArrivalsValue = $recentArrivalsSynopsisNode.SelectSingleNode("dd").InnerText
#Update post content here
#[Math]::Round((8732/13506)*100)
############################
$response=$response -replace '<dd>\d+(\.\d+)?%</dd>',"<dd>$([Math]::Round(($HasProjectUrl/$recentArrivalsValue)*100,2))%</dd>"
$response=$response -replace '<dd>\d{2}/\d{2}/\d{4}</dd>', "<dd>$Date</dd>"
$response=$response -replace '<dt>\d+.*?</dt>',"<dt>$HasProjectUrl modules stand out, they come with a ProjectUrl — an extra layer of understanding and context with use cases, documentation, and more.</d>"

$dataPointCount = ([regex]::Matches($response, '<div class="data-point"')).Count

$matches = [regex]::Matches($response, '<li style="--x: \d+px; --y: \d+\.?\d*px;">.*?')
$latestLi = $matches[$matches.Count - 1].Value
$x=40+(($latestLi -split ':') -split ';')[1].Replace('px',"").Trim()
$oldY=(($latestLi -split ':') -split ';')[3].Replace('px',"").Trim()
$y=$HasProjectUrl/100
$dataValue=25
$lineSegment = "<div class=`"line-segment`" style=`"--hypotenuse: 40; --angle:$($oldY-$y);`"></div>"
$response=$response | ConvertFrom-Html
$liNodes = $response.SelectNodes("//li")
$lineSegmentNode = [HtmlAgilityPack.HtmlNode]::CreateNode($linesegment)
$liNodes[-1].AppendChild($lineSegmentNode)
$newEntry=@"
<li style="--x: $($x)px; --y: $($y)px;">
            <div class="data-point" data-value="$($dataValue)">
              <span class="tooltiptext">$HasProjectUrl</span>
              <p>
                $(get-date -Format MMM-yy)
              </p>
            </div>
          </li>
"@
$newEntryNode = [HtmlAgilityPack.HtmlNode]::CreateNode($newEntry)
$liNodes[-1].ParentNode.AppendChild($newEntryNode)
#}
if ($dataPointCount -ge 12) {
    <# remove 1st #>
    $liNodes.RemoveAt(0)
}
############################

#commit changes
$UpdatedPostBase64=[Convert]::ToBase64String($OutputEncoding.GetBytes($response))
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
$response = Invoke-RestMethod -Uri $commitUrl -Headers $headers -Method Put -Body $jsonBody

#fetch index page
#update it
#commit changes