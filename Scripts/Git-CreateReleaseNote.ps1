param ([string]$from, [string]$to, [bool]$interpretFromAsTagFilter)

function DisplayDoc(){
    Write-Host This script allow to extract merges that occurs on current branch between the two git commits.
    Write-Host To use it, you must call .\CreateReleaseNote.ps1 -from xxx -to yyy
    Write-Host Current execution folder must be the git repository path
    Write-Host Arguments :
    Write-Host " -from   [Required] identify either a sha or a tag (or regex)"
    Write-Host " -to     [Optional] identify either a sha or a tag, if empty : HEAD"
    Write-Host " -interpretFromAsTagFilter [Optional] if true : interpret -from as regex to found last tag"
    Write-Host "  this last arg need that tags are flagged as Annotated"
}

function ExtractMerges(){

    git log "$($from)..$($to)" --pretty="format:%H %cd %s" --date=short | 
    ForEach-Object { Select-string -InputObject $($_) -Pattern "(?<sha>\b[0-9a-f]{5,40}\b)\s(?<date>\d{4}-\d{2}-\d{2}).+(?<branch>(feature|bugfix)[^\s']+).+" } |
    ForEach-Object { $_.Matches } |
    ForEach-Object {  "$($_.Groups["sha"].Value) $($_.Groups["date"].Value) $($_.Groups["branch"].Value)" }

}

function InterpretFromArg (){
    $from=git for-each-ref --sort=-taggerdate | 
    ForEach-Object { Select-string -InputObject $($_) -Pattern "$($from)" } |  
    ForEach-Object { $_.Matches } | ForEach-Object { "$($_.Groups["Tag"])" } | 
    Select-Object $_ -First 1
    return $from;
}

if($to -eq $false){
    $to = "HEAD";
}

if($from -and $to){
    if($interpretFromAsTagFilter){
        $regex=$from;
        $from=InterpretFromArg;
        Write-Host Interpret from regex $($regex) - Found From Tag : $from
    }

    ExtractMerges;
}else{
    DisplayDoc;
}
