param(
        [Parameter(Mandatory=$True)][string]$projectCollectionUrl,
        [Parameter(Mandatory=$True)][string]$feedName,
        [Parameter(Mandatory=$True)][string]$packageName,
        [Parameter(Mandatory=$True)][string]$packageVersion,
        [Parameter(Mandatory=$True)][string]$promotedQuality
    )

function Get-FeedMetadata{
    param(
        [Parameter(Mandatory=$True)][string]$projectUrl,
        [Parameter(Mandatory=$True)][string]$feedName
    )

    $feedRelativeUri="/_apis/packaging/feeds/";

    $result=@{};

    try {
        # Get feed metadata
        $feedByNameUri = "$($projectUrl)$($feedRelativeUri)$($feedName)";
        Write-Verbose "Trying to get feed metadata: $feedByNameUri";
        $feedResponse = Invoke-RestMethod -Uri $feedByNameUri -ContentType "application/json" -Method Get -UseDefaultCredentials;

        # Get feed's views metadata
        $viewsUri="$($feedResponse._links.self.href)/Views";
        Write-Verbose "Trying to get feed views metadata: $viewsUri";
        $viewsResponse = Invoke-RestMethod -Uri $viewsUri -ContentType "application/json" -Method Get -UseDefaultCredentials;
        
    } catch {
        $excMsg = "$($_.Exception.ToString())`n$($_.ScriptStackTrace)";
        throw "Unhandled exception while reading feed $feedName`n$excMsg"
    }

    if ($null -eq $feedResponse) {
        throw "Feed $feedName could not be found in project $projectUrl";
    }

    $result.Name        = $feedResponse.name;
    $result.Id          = $feedResponse.id;
    $result.Links       = @{};
    $result.Links.Self  = $feedResponse._links.self;
    $result.Links.Packages  = $feedResponse._links.Packages;

    $result.Views = @{};
    $viewsResponse.Value |`
        ForEach-Object {
            $result.Views.Add($_.name, @{ 
                "Id"    =$_.id
                "Name"  =$_.name
                "Links" = @{
                    "Self"  = $_._links.self
                    "Packages"  = $_._links.packages
                };
            });
    };

    return $result;
}

function Get-PackageMetadata{
    param(
        [Parameter(Mandatory=$True)][hashtable]$feedMetadata,
        [Parameter(Mandatory=$True)][string]$packageName,
        [Parameter(Mandatory=$True)][string]$packageVersion
    )

    $result=@{};

    try {
        # Retrieve packages to find metadata for $packageName
        $packagesUri = "$($feedMetadata.Links.Packages.href)";
        Write-Verbose "Trying to retrieve packages information: $packagesUri";

        # Extract package metadata 
        $currentPackage = $(Invoke-RestMethod -Uri $packagesUri -UseDefaultCredentials -ContentType "application/json" -Method Get).Value |`
            Where-Object { $_.Name -eq $packageName } |`
            Select-Object -First 1;

        # Extract version metadata
        $currentVersion = $(Invoke-RestMethod -Uri $currentPackage._links.versions.href -UseDefaultCredentials -ContentType "application/json" -Method Get).Value |`
            Where-Object { $_.version -eq $packageVersion } |`
            Select-Object -First 1;

    } catch {
        $excMsg = "$($_.Exception.ToString())`n$($_.ScriptStackTrace)";
        throw "Unhandled exception while reading feed $($feedMetadata.Name)`n$excMsg";
    }

    if ($null -eq $currentVersion) {
        throw "Package $($packageName) could not be found";
    }

    $result.Name        = $currentPackage.name;
    $result.Package     = $currentPackage;
    $result.VersionName = $currentVersion.version;
    $result.Version     = $currentVersion

    return $result;
}

function Promote{
    param(
        [Parameter(Mandatory=$True)][hashtable]$feedMetadata,
        [Parameter(Mandatory=$True)][string]$packageName,
        [Parameter(Mandatory=$True)][string]$packageVersion,
        [Parameter(Mandatory=$True)][string]$targetFeedView
    )

    $targetViewMetadata = $feedMetadata.Views[$targetFeedView];

    if($null -eq $targetViewMetadata){
        throw "View $($targetFeedView) could not be found in feed $($feedMetadata.Name)";
    }

    $body=ConvertTo-Json @{
        "views" =@{
            "path"  ="/views/-"
            "op"    =  "add"
            "value" = $targetViewMetadata.Id
        }
    };

    try {
        $feedByNameUri = "$($feedMetadata.Links.Self.href)/nuget/packages/$($packageName)/versions/$($packageVersion)?api-version=5.0-preview.1";
        Write-Verbose "Trying to retrieve feed information: $feedByNameUri";
        Invoke-RestMethod -Uri $feedByNameUri -ContentType "application/json" -Method Patch -Body $body -UseDefaultCredentials;
    } catch {
        $excMsg = "$($_.Exception.ToString())$([System.Environment]::NewLine)$($_.ScriptStackTrace)";
        throw "Unhandled exception while reading feed $feedName`n$excMsg";
    }

}

function Main{
    param(
        [Parameter(Mandatory=$True)][string]$projectCollectionUrl,
        [Parameter(Mandatory=$True)][string]$feedName,
        [Parameter(Mandatory=$True)][string]$packageName,
        [Parameter(Mandatory=$True)][string]$packageVersion,
        [Parameter(Mandatory=$True)][string]$promotedQuality
    )

    $feedMetadata = Get-FeedMetadata -projectUrl $projectCollectionUrl -feedName $feedName;
    #$packageMetadata = Get-PackageMetadata -feedMetadata $feedMetadata -packageName "LODH.Gef3.Portfolios.Derivatives" -packageVersion "8.0.490-debug";
    Promote -feedMetadata $feedMetadata -packageName $packageName -packageVersion $packageVersion -targetFeedView $promotedQuality;
}

Main -projectCollectionUrl $projectCollectionUrl -feedName $feedName -packageName $packageName -packageVersion $packageVersion -promotedQuality $promotedQuality;