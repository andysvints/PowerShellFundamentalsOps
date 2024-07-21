#region Helper Functions

function Invoke-PSGalleryModulesProcessing
{
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
    [CmdletBinding(SupportsShouldProcess=$true, 
                  ConfirmImpact='Medium')]
    [Alias()]
    Param
    (
        # PSGallery API url filtering modules to be processed
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("URI")] 
        $URL
    )

    Begin
    {
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("$URL"))
        {
            $count=1
            $PSGalleryResp=(Invoke-WebRequest -Uri $URL).Content

            $PSGalleryLatestModuleVersion=[System.Xml.XmlDocument]$PSGalleryResp
            foreach($module in $($PSGalleryLatestModuleVersion.feed.entry.properties)){
                $count++
                if($count -eq 20){
                    Start-Sleep 10
                    $count=1
                }
                $doc=$($module |
                Select-Object @{l="id";e={$_.id}}, Version,NormalizedVersion,Authors,Copyright, 
                @{l="Created";e={$_.Created."#text"}},Dependencies,Description,
                @{l="DownloadCount";e={$_.DownloadCount."#text"}},GalleryDetailsUrl,
                IconUrl, @{l="IsLatestVersion";e={$_.IsLatestVersion."#text"}},
                @{l="IsAbsoluteLatestVersion";e={$_.IsAbsoluteLatestVersion."#text"}},
                @{l="IsPrerelease";e={$_.IsPrerelease."#text"}},Language,	
                @{l="LastUpdated";e={$_.LastUpdated."#text"}},@{l="Published";e={$_.Published."#text"}},	
                PackageHash,PackageHashAlgorithm,@{l="PackageSize";e={$_.PackageSize."#text"}},ProjectUrl,
                ReportAbuseUrl,ReleaseNotes,@{l="RequireLicenseAcceptance";e={$_.RequireLicenseAcceptance."#text"}},
                Summary,Tags, @{l="TagsCount";e={$_.Tags.split().count}},
                Title,@{l="VersionDownloadCount";e={$_.VersionDownloadCount."#text"}},
                LicenseUrl,ItemType,FileList,@{l="FileCount";e={$_.FileList.split('|').count}},GUID,PowerShellVersion,
                DotNetFrameworkVersion,CLRVersion,ProcessorArchitecture,CompanyName,Owners,@{l="OwnersCount";e={$_.Owners.split(',').count}}
                | ConvertTo-Json)
                
#TODO: ADD EXPONENTIAL BACKOFF AND RETRY

New-CosmosDbDocument -Context $cosmosDbContext -CollectionId 'psgallery' -DocumentBody $doc  -PartitionKey "$($module.id.tostring())"
            }

            if($PSGalleryLatestModuleVersion.feed.link.href.count -eq 2){
                Start-sleep 30
                $NextLink=$PSGalleryLatestModuleVersion.feed.link.href[-1]
                Write-Verbose "Next Link: $($NextLink)"
                Invoke-PSGalleryModulesProcessing -Uri $NextLink
            }

        }
    }
    End
    {
    }
}
#endregion



#Get 1st 100 items
#$PSGalleryResp=(Invoke-WebRequest -Uri "https://www.powershellgallery.com/api/v2/Packages()?`$filter=IsLatestVersion%20eq%20true").Content

Import-Module CosmosDB
#https://www.powershellgallery.com/packages/CosmosDB

$resourceGroupName = "CosmosDB-Rg"
$cosmosDbAccountName = "andysdb"
$databaseName = "psgallerystats"
Connect-AzAccount -Tenant "1687efe7-c70e-4095-a272-fbba59d3d524"
#Connect-AzAccount
$cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $resourceGroupName 

#Process 1st 100
#$PSGalleryLatestModuleVersion=[System.Xml.XmlDocument]$PSGalleryResp
<#
foreach($module in $($PSGalleryLatestModuleVersion.feed.entry.properties)){
    $doc=$($module |
    Select-Object @{l="id";e={$_.id}}, Version,NormalizedVersion,Authors,Copyright, 
    @{l="Created";e={$_.Created."#text"}},Dependencies,Description,
    @{l="DownloadCount";e={$_.DownloadCount."#text"}},GalleryDetailsUrl,
    IconUrl, @{l="IsLatestVersion";e={$_.IsLatestVersion."#text"}},
    @{l="IsAbsoluteLatestVersion";e={$_.IsAbsoluteLatestVersion."#text"}},
    @{l="IsPrerelease";e={$_.IsPrerelease."#text"}},Language,	
    @{l="LastUpdated";e={$_.LastUpdated."#text"}},@{l="Published";e={$_.Published."#text"}},	
    PackageHash,PackageHashAlgorithm,@{l="PackageSize";e={$_.PackageSize."#text"}},ProjectUrl,
    ReportAbuseUrl,ReleaseNotes,@{l="RequireLicenseAcceptance";e={$_.RequireLicenseAcceptance."#text"}},
    Summary,Tags, @{l="TagsCount";e={$_.Tags.split().count}},
    Title,@{l="VersionDownloadCount";e={$_.VersionDownloadCount."#text"}},
    LicenseUrl,ItemType,FileList,@{l="FileCount";e={$_.FileList.split('|').count}},GUID,PowerShellVersion,
    DotNetFrameworkVersion,CLRVersion,ProcessorArchitecture,CompanyName,Owners,@{l="OwnersCount";e={$_.Owners.split(',').count}}
    | ConvertTo-Json)
    New-CosmosDbDocument -Context $cosmosDbContext -CollectionId 'psgallery' -DocumentBody $doc  -PartitionKey "$($module.id.tostring())"
}
#>

#Invoke-PSGalleryModulesProcessing -URL 'https://www.powershellgallery.com/api/v2/Packages()?$filter=IsLatestVersion%20eq%20true&$skip=8150' -Verbose


#add exponential back off 

Invoke-PSGalleryModulesProcessing -URL 'https://www.powershellgallery.com/api/v2/Packages()?$filter=IsLatestVersion%20eq%20true' -Verbose








