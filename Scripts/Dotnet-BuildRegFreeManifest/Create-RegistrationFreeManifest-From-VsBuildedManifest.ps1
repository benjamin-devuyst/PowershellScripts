param(
    [Parameter(Mandatory=$true, HelpMessage="Folder where the binaries are build")]
    [System.IO.DirectoryInfo]$binariesFolder,
    
    [Parameter(Mandatory=$true, HelpMessage="List of assemblies separated by a ';' that must be taken in Com Manifest override")]
    [string]$assembliesWithinComInside,

    [Parameter(Mandatory=$true, HelpMessage="Application manifest file name (must exists && with extension). Ex. [AppName].exe.manifest")]
    [ValidatePattern("^[\w-]+\.exe.manifest")]
    [string]$appManifestFileName)

# params
$folder = $binariesFolder; #[System.IO.DirectoryInfo]"E:\repos\regfree\G2Interface\GEF2\Bin";
$assemblies = $assembliesWithinComInside -split ";";
$appManifest = [System.IO.Path]::Combine($folder.FullName, $appManifestFileName);

# common immutable stuffs
$commonManifestExtension = ".manifest";
$commonWinSdkAppManifestTransformTool = "$PSScriptRoot\mt.exe";

function ValidateArgs{
    if($binariesFolder.Exists -eq $false){
        Write-Error "Arg binariesFolder must exists";
        return $false;
    }

    if([System.IO.File]::Exists($appManifest) -eq $false){
        Write-Error "Arg appManifest must exists";
        return $false;
    }
    
    return $true;
}

function AddManifestDependencyForDotNetComponent{
    param([System.IO.FileInfo]$assemblyFile,[System.IO.FileInfo]$targetAppManifest)

    # filename is important for windows sxs resolution... => '[assemblyName].manifest'
    $assemblyManifestName="$($assemblyFile.FullName.Replace($assemblyFile.Extension, $commonManifestExtension))";
    
    try {
        #   1. extract the assembly com dependency manifest with mt.exe
        & $commonWinSdkAppManifestTransformTool -managedassemblyname:"$($assemblyFile.FullName)" -nodependency -out:"$assemblyManifestName";

        #   2. get assembly identity from generated manifest
        $xmlAssemblyManifest=[xml](Get-Content $assemblyManifestName);
        $assemblyIdentityFromAssemblyManifest=$xmlAssemblyManifest.SelectSingleNode("//*[local-name() = 'assemblyIdentity']");
        
        #   3. inject the identity into the app manifest (no mt.exe function to do that > xml modification...)
        $xmlAppManifest=[xml](Get-Content $targetAppManifest.FullName);
    } catch {
        # prevent adding empty parts to the main manifest
        return;
    }

    #   target xml structure inside the documentroot for a dotnet Com dependency :
    #   <dependency>
    # 		<dependentAssembly>  
    # 			<assemblyIdentity ... />
    # 		</dependentAssembly>  
    # 	</dependency>

    $assemblyIdentityForAppManifest=$xmlAppManifest.ImportNode($assemblyIdentityFromAssemblyManifest, $true);
    $defaultNamespaceUri=$xmlAppManifest.DocumentElement.NamespaceURI;
    
    $childDependency=$xmlAppManifest.CreateElement("dependency", $defaultNamespaceUri);
    $childDependencyAssembly=$xmlAppManifest.CreateElement("dependentAssembly", $defaultNamespaceUri);

    $xmlAppManifest.DocumentElement.AppendChild($childDependency);
    $childDependency.AppendChild($childDependencyAssembly);
    $childDependencyAssembly.AppendChild($assemblyIdentityForAppManifest);

    $xmlAppManifest.Save($targetAppManifest.FullName);
}

if (ValidateArgs -eq $true) {
    Get-ChildItem $folder |`
    Where-Object { $_.PSIsContainer -eq $false -and $assemblies.Contains($_.Name) } |`
    ForEach-Object {
        # Com over dotnet -> for delphi 
        AddManifestDependencyForDotNetComponent -assemblyFile $_.FullName -targetAppManifest $appManifest
    }
}
