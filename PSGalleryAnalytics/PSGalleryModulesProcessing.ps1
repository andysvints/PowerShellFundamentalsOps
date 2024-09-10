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
            foreach($module in $($PSGalleryLatestModuleVersion.feed.entry)){
                $count++
                if($count -eq 20){
                    Start-Sleep 10
                    $count=1
                }

                $doc=$($module |Select-Object @{l="id";e={$_.properties.id}}, 
                @{l="Version";e={$_.properties.Version}},
                @{l="NormalizedVersion";e={$_.properties.NormalizedVersion}},
                @{l="Authors";e={$_.properties.Authors}},
                @{l="Copyright";e={$_.properties.Copyright}},
                @{l="Created";e={$_.properties.Created."#text"}}, 
                @{l="Dependencies";e={$_.properties.Dependencies}},
                @{l="Description";e={$_.properties.Description}},
                @{l="DownloadCount";e={$_.properties.DownloadCount."#text"}},
                @{l="GalleryDetailsUrl";e={$_.properties.GalleryDetailsUrl}},
                @{l="IconUrl";e={$_.properties.IconUrl}}, 
                @{l="IsLatestVersion";e={$_.properties.IsLatestVersion."#text"}},
                @{l="IsAbsoluteLatestVersion";e={$_.properties.IsAbsoluteLatestVersion."#text"}},
                @{l="IsPrerelease";e={$_.properties.IsPrerelease."#text"}},
                @{l="Language";e={$_.properties.Language}},
                @{l="LastUpdated";e={$_.properties.LastUpdated."#text"}},
                @{l="Published";e={$_.properties.Published."#text"}},
                @{l="PackageHash";e={$_.properties.PackageHash}},
                @{l="PackageHashAlgorithm";e={$_.properties.PackageHashAlgorithm}},
                @{l="PackageSize";e={$_.properties.PackageSize."#text"}},
                @{l="ProjectUrl";e={$_.properties.ProjectUrl}},
                @{l="ReportAbuseUrl";e={$_.properties.ReportAbuseUrl}},
                @{l="ReleaseNotes";e={$_.properties.ReleaseNotes}},
                @{l="RequireLicenseAcceptance";e={$_.properties.RequireLicenseAcceptance."#text"}},
                @{l="Summary";e={$_.properties.Summary}},
                @{l="Tags";e={$_.properties.Tags}}, 
                @{l="TagsCount";e={$_.properties.Tags.split().count}},
                @{l="Title";e={$_.properties.Title}},
                @{l="VersionDownloadCount";e={$_.properties.VersionDownloadCount."#text"}},
                @{l="LicenseUrl";e={$_.properties.LicenseUrl}},
                @{l="ItemType";e={$_.properties.ItemType}},
                @{l="FileList";e={$_.properties.FileList}},
                @{l="FileCount";e={$_.properties.FileList.split('|').count}},
                @{l="GUID";e={$_.properties.GUID}},
                @{l="PowerShellVersion";e={$_.properties.PowerShellVersion}},
                @{l="DotNetFrameworkVersion";e={$_.properties.DotNetFrameworkVersion}},
                @{l="CLRVersion";e={$_.properties.CLRVersion}},
                @{l="ProcessorArchitecture";e={$_.properties.ProcessorArchitecture}},
                @{l="CompanyName";e={$_.properties.CompanyName}},
                @{l="Owners";e={$_.properties.Owners}},
                @{l="OwnersCount";e={$_.properties.Owners.split(',').count}},
                @{l="NugetPkgLink";e={$module.content.src}},
                @{l="Updated";e={$_.properties.updated}},
                @{l="Scoring";e={"NaN"}}
                |ConvertTo-Json)

                
#TODO: ADD EXPONENTIAL BACKOFF AND RETRY

New-CosmosDbDocument -Context $cosmosDbContext -CollectionId 'psgallery' -DocumentBody $doc  -PartitionKey "$($module.properties.id)" -Upsert $true
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

#$PSGalleryResp=(Invoke-WebRequest -Uri 
#"https://www.powershellgallery.com/api/v2/Packages()?`$filter=IsLatestVersion%20eq%20true%20and%20Created%20gt%20DateTime'2024-07-23T00:00:00'")
#can filter by hour too Created%20gt%20DateTime'2024-07-23T23:50:00'"

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

Invoke-PSGalleryModulesProcessing -URL "https://www.powershellgallery.com/api/v2/Packages()?`$filter=IsLatestVersion%20eq%20true%20and%20Created%20lt%20DateTime'2024-07-29T22:00:00'" -Verbose








