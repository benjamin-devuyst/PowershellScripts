# PowershellScripts

## Create Release Note Powershell Script - Git-CreateReleaseNote.ps1

This script allows you to extract all branch names that were merged between two commits.
The output format is 'sha date branchName'

### Use
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
