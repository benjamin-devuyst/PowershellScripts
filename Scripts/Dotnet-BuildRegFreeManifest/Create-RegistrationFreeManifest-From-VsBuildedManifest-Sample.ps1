$binariesFolder = "C:\WK\SolutionRoot\PathToSolutionBinOutput\Bin";
$solutionPath = "C:\WK\SolutionRoot\MySolution.sln";
$appManifestFileName = "MainApp.exe.manifest";

$assembliesList = Invoke-Expression -Command "$PSScriptRoot\Create-SolutionAssemblyList.ps1 -solutionPath $solutionPath"
$assembliesWithinComInside = $assembliesList -join ";";

Invoke-Expression -Command "$PSScriptRoot\Create-RegistrationFreeManifest-From-VsBuildedManifest.ps1 -binariesFolder $binariesFolder -appManifestFileName $appManifestFileName -assembliesWithinComInside ""$assembliesWithinComInside""";
