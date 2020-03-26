# PowershellScripts

## Create Release Note Powershell Script - Git-CreateReleaseNote.ps1

This script allows you to extract all branch names that were merged between two commits.
The output format is 'sha date branchName'

### Usage
1. Simple use (manual) : extract merges between two sha or tags  
   1. Open a powershell console into the git repository  
   2. Execute script :  
      PS C:\MyGitRepos> .\[ScriptPath]\CreateReleaseNote.ps1 -from *sha/tag* -to *sha/tag*
   
2. Auto detect the argument 'from' from a regular expression.  
This will extract merges between a 'from' that match a regular expression and current Head.  
.\CreateReleaseNote.ps1 -from "CI-Auto-.+" -interpretFromAsRegex $true  
**Remark** : Here, the tag's regular expression matches "CI-AUTO-.+", that means 'CI-Auto' followed by one or multiple char(s)

### Use case
#### Context
In a normal use of git, the developer creates a branch for each feature or bug. When the task has ended, he made a merge (manual or better, by pull request) into the master (or release) branch.
If the devteam has a continuous integration system (like jenkins of tfs builds), all release builds can be construct by this tool. In that kind of system, the commit that is used for the build is tagged.

#### Use of the script
In that kind of environment, the script can be called at the start of the release build to list all changes that were done from the last release build (identified by the annotated tag).
The result will be that the output of the build will display these modifications.

## Create Registration Free Manifest for all projects of a solution - \Dotnet-BuildRegFreeManifest\Create-RegistrationFreeManifest-From-VsBuildedManifest.ps1
  
Sometimes, you have to use or expose some COM components to other technologies inside your app (for example : a dotnet UI app that embed Delphi...), and deploy them together.  
These combinaison of scripts offer you a way to automate the build of a registration free app from all assemblies.
This will simplify the deployment, and avoiding regsvr of COM dlls.  

## Usage

      1. In Visual Studio, ask him to build the manifest outside of the exe.
         *By default, this manifest is present, but is embed as a resource in the executable. This action will make it available as a Side by Side file (SxS)*
      2. Write a Powershell script like Create-RegistrationFreeManifest-From-VsBuildedManifest-Sample.ps1  
         *This script aggregate the context before calling the task script*
      3. Add a call to your script (create at 2.) from the application project PostBuild event.

      The script will complete the externally manifest builded by Visual Studio (name: YourAppName.exe.manifest), and build all assemblies dll SxS manifests.

## Azure Devops Promote package - AzureDevops-PromotePackage.ps1

Promoting packages in Artifacts is possible accross Powershell with this script.  
This script also contains a method to extract all metadata about Feeds, Views, Packages. All calls to AzureDevops are made accross Rest Api (which is HateOAS).

## Usage

Call the script with following args :

 - Project Collection Url ( -projectCollectionUrl https://... )
 - The name of the Feed concerned ( -feedName MyFeed )
 - The name of the Nuget package ( -packageName ... )
 - The version of the Nuget package ( -packageVersion ... )
 - The name of the quality (or view) in the feed to promote to ( -promotedQuality PreRelease --> for example)

 