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

$RecentArrivals=$PSDocuments | ConvertTo-Json -Depth 10

$githubToken = Get-AzKeyVaultSecret -VaultName "PSFundamentals-KV" -Name "GitHubPAT" -AsPlainText

$owner = $env:GitHubUser
$repo = $env:GitHubRepo
$branch = $env:GitHubBranch
$Date=$(get-date -Format MM/dd/yyyy)
$indexFilePath = "index.html"
$postFilePath="_posts/2024-02-14-recent-arrivals.html"
$commitMessage = "$Date update post#1"

$headers = @{
    Authorization = "Bearer $githubToken"
    Accept = "application/vnd.github.v3+json"
}

# Get the file SHA (to update existing post)
$postApiUrl = "https://api.github.com/repos/$owner/$repo/contents/$($postFilePath)?ref=$($branch)"
$response = Invoke-RestMethod -Uri $postApiUrl -Headers $headers -Method Get
$postSha = $response.sha

#Get post file content
$headers = @{
    Authorization = "Bearer $githubToken"
    Accept = "application/vnd.github.raw+json"
}
$response = Invoke-RestMethod -Uri $postApiUrl -Headers $headers -Method Get

#Update post content here
$response=$response -replace '<dd>\d+</dd>',"<dd>$RecentArrivals</dd>"
$response=$response -replace '<dd>\d{2}/\d{2}/\d{4}</dd>', "<dd>$Date</dd>"
$dataPointCount = ([regex]::Matches($response, '<div class="data-point"')).Count

if($dataPointCount -lt 12){
    #just append at the bottom
    $matches = [regex]::Matches($response, '<li style="--x: \d+px; --y: \d+\.?\d*px;">.*?')
    $latestLi = $matches[$matches.Count - 1].Value
    $x=40+(($latestLi -split ':') -split ';')[1].Replace('px',"").Trim()
    $oldY=(($latestLi -split ':') -split ';')[3].Replace('px',"").Trim()
    $y=$RecentArrivals/100
    $dataValue=95
    $lineSegment = "<div class=`"line-segment`" style=`"--hypotenuse: 40; --angle:$($oldY-$y);`"></div>"
    $response=$response -replace '(<div class="data-point".*?</p>\s*</div>)', "`$1`n$lineSegment" -replace "(</li>\s*</ul>)", "$lineSegment`n$1"
    $newEntry=@"
<li style="--x: $($x)px; --y: $($y)px;">
            <div class="data-point" data-value="$($dataValue)">
              <span class="tooltiptext">$RecentArrivals</span>
              <p>
                $(get-date -Format MMM-yy)
              </p>
            </div>
          </li>
"@
    $response=$response -replace '(</ul>\s*</figure>)', "$newEntry`n`$1"
}elseif ($dataPointCount -eq 12) {
    <# remove 1st #>
    #append the new one
}

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

