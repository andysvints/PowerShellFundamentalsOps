# Input bindings are passed in via param block.
param($Timer)

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
$commitMessage = "$Date update post#2"

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
############################

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