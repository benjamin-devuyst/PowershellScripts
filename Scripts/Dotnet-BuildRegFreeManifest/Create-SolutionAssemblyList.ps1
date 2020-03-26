param(
    [Parameter(Mandatory=$true)]
    [System.IO.FileInfo]$solutionPath
    )
    
# Analyzes a csproj file in order to find the real output assembly's name
function Get-ProjectAssemblyName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$projectPath
    )
    
    $xml = [xml](Get-Content $projectPath)
    $assemblyName = $xml.SelectSingleNode("//*[local-name() = 'AssemblyName']").'#text';
    $outputType = $xml.SelectSingleNode("//*[local-name() = 'OutputType']").'#text';
    $extension = $(if ($outputType -eq "Library") { "dll" } else { "exe" });
    
    return "$assemblyName.$extension";
}

# Analyzes a solution file in order to list projects' assemblies
function Get-ProjectsFromSolution {
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$solutionPath
    )

    $assemblies = @();

    Get-Content $solutionPath |
        Select-String 'Project\(' |
            ForEach-Object {
                if ($_ -like "*.csproj*") {
                    $projectParts = $_ -Split '[,=]' | ForEach-Object { $_.Trim('[ "{}]') };
                    $projectPath = "$($solutionPath.Directory.FullName)\$($projectParts[2])";
                    $assemblyName = Get-ProjectAssemblyName -projectPath $projectPath;
                    # Take only dlls
                    if ($assemblyName.EndsWith(".dll")) {
                        $assemblies += $assemblyName;
                    }
                }
            };
    
    return $assemblies | sort;
}

Get-ProjectsFromSolution -solutionPath $solutionPath;
