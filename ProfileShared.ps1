$window = $Host.UI.RawUI
$window.BackgroundColor = "black"

# This stores info on the commands in the profile.
$profileList = @{}

function ListAddCommand
{
    param([string] $command, [string]$helpLine)
    $profileList[$command] = $helpLine
}

"list - list all profile commands"
function list
{
    $profileList
    #ForEach($listCommand in $profileList.Keys)
    #{
    #    $listInfo = $profileList[$listCommand]
    #    "- $listCommand `t`t$listInfo"
    #}
}

ListAddCommand "open" "alias open -> explorer.exe"
Set-Alias open explorer.exe

Set-Alias chrome 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'

$profileUrls = @{}

function AddUrl
{
    param([string]$site, [string]$url)
    $profileUrls[$site] = $url
}

AddUrl "gh" "https://github.com/chestercodes/"
AddUrl "blog" "https://chester.codes"

ListAddCommand "c" "c - chrome shortcuts -> 'c list' for urls"
function c
{
    param([string]$a)
    
    if($a -eq "list"){ $profileUrls }
    else 
    {
        if($profileUrls.ContainsKey($a))
        {
            chrome $profileUrls[$a]
        }
        else
        {
            chrome $a
        }
    }
}

function AddPlace
{
    param([string]$name, [string]$location)
    
    if($profilePlaces -eq $null)
    {
        $profilePlaces = @{}
    }

    $profilePlaces[$name] = $location
}

ListAddCommand "d" "cd to `$startingDir"
function d
{
    cd $startingDir
}

ListAddCommand "goto" "'goto' - open a commonly used place - use 'goto list' for places"
function goto
{
    param([string]$place)
    if($profilePlaces -eq $null)
    {
        "Need to set a places variable..."
        return
    }
    
    $place = $place.ToLower()
    
    if($place -eq "list"){ $profilePlaces }
    else 
    {
        if($profilePlaces.ContainsKey($place))
        {
            explorer.exe $profilePlaces[$place]
        }
        else
        {
            "haven't met '$place' yet"
        }
    }
}


ListAddCommand "g" "'g' - cd to a commonly used place - use 'g list' for places"
function g
{
    param([string]$place)
    if($profilePlaces -eq $null)
    {
        "Please set a profilePlaces variable"
        return
    }
    
    $placesOrParentDirs = @{}
    $profilePlaces.Keys | ForEach-Object { $placesOrParentDirs[$_] = GetDirOrParent $profilePlaces[$_] }

    $place = $place.ToLower()
    
    if($place -eq "list"){ $placesOrParentDirs }
    else 
    {
        if($placesOrParentDirs.ContainsKey($place))
        {
            cd $placesOrParentDirs[$place]
        }
        else
        {
            "haven't met '$place' yet"
        }
    }
}

function GetDirOrParent
{
    param([string]$fileOrFolder)
    if(Test-Path $fileOrFolder -pathtype container)
    { 
        return $fileOrFolder
    }else{ 
        $file = Get-Item $fileOrFolder
        return $file.Directory.FullName
    }
}

ListAddCommand "gs" "shortcut for git status"
function gs
{
    git status
}

ListAddCommand "gf" "shortcut for git fetch"
function gf
{
    git fetch
}

ListAddCommand "gd" "shortcut for git diff"
function gd
{
    git diff
}

ListAddCommand "gdc" "shortcut for git diff --cached"
function gdc
{
    git diff --cached
}

ListAddCommand "gfs" "fetches and shows status"
function gfs
{
    git fetch
    git status
}

ListAddCommand "reb-dev" "shortcut for git rebase -p origin/develop"
function reb-dev
{
    git rebase -p origin/develop
}

ListAddCommand "frebra" "fetch then rebase origin/branch preserving merges"
function frebra
{
    $currentBranch = git rev-parse --abbrev-ref HEAD
    git fetch
    git rebase -p "origin/$currentBranch"
}

ListAddCommand "reb-con" "shortcut for git rebase --continue"
function reb-con
{
    git rebase --continue
}

ListAddCommand "commit" "commit all the changes with message"
function commit
{
    param([string]$message)
    git add -A
    git commit -m $message
}

ListAddCommand "com" "'com' - commit with message that starts with jira item from branch name"
function com
{
    param([string]$message)

    $jiraItemRegex = "^feature\/[A-Za-z]+(\-|_)\d+"
    $currentBranch = git rev-parse --abbrev-ref HEAD
    
    if($currentBranch -match $jiraItemRegex)
    {
        $jiraItem = $Matches[0].Replace("feature/", "")

        git commit -m "$jiraItem`: $message"
    }
    else
    {
        "JIRA item matching didn't work."
        $yesOrSomethingElse = Read-Host -Prompt "Enter 'y' to commit to branch '$currentbranch'. Anything else will abort"
        if($yesOrSomethingElse.ToLower() -eq "y")
        {
            git commit -m "$message"
        }
    }
}

ListAddCommand "newps" "'newps' - open powershell prompt with different user creds"
function newps
{
    Start-Process powershell.exe -Credential (Get-Credential)
}

ListAddCommand "path" ""
function path($filterBy){
    $res = $env:Path.Split(';')
    if([string]::IsNullOrWhiteSpace($filterBy) -eq $false){
        $res | Select-String -SimpleMatch $filterBy
    } else {
        $res
    }
}

ListAddCommand "nuke-get" "Delete all current nuget caches"
function nuke-get(){
    $caches = nuget locals all -list
    foreach ($cache in $caches){
        $cacheSplit = $cache.Split(":")
        $cacheName = $cacheSplit[0]
        $cachePath = $cache.Replace("$cacheName`: ", "")
        "Deleting cache '$cacheName' at '$cachePath'"
        if(Test-Path $cachePath){
            Remove-Item -path "$cachePath\*" -Recurse
        } else {
            "Nothing at path"
        }
        
        "Done"
    }
}

function clone ([string]$url){
    if([string]::IsNullOrWhiteSpace($url)){
        Write-Error "please provide url"
        return ""
    }
    $urlParts = $url.Split('/')
    if($url.StartsWith("http")){
        # https://github.com/CBurbidge/CBurbidge.github.io.git
        $org = $urlParts[3]
        $repoPart = $urlParts[4]
        $repo = $repoPart.Substring(0, $repoPart.Length - ".git".Length)
    } elseif($url.StartsWith("git")){
        # git@github.com:CBurbidge/CBurbidge.github.io.git
        $org = $urlParts[0].Substring("git@github.com:".Length)
        $repoPart = $urlParts[1]
        $repo = $repoPart.Substring(0, $repoPart.Length - ".git".Length)
    } else {
        Write-Error "Cant parse url $url"
        return ""
    }

    $directory = "$repoBase\$org\$repo"
    Write-host "going to clone to $directory"
    git clone $url $directory
    
    return $directory

}

function clonecd ([string]$url){
    $directory = clone $url
    if(([string]::IsNullOrEmpty($directory))){

    } else {
        cd $directory
    }
    
}


ListAddCommand "cur" "cd to current"
function cur(){
    $currentWorkingDir = [IO.File]::ReadAllText($currentFile)
    cd $currentWorkingDir
}

ListAddCommand "set-cur" "set current wd"
function set-cur($location){
    [IO.File]::WriteAllText($currentFile, $location)
}


function prompt
{
    $str = "$pwd".Split('\') | Select-Object -last 1
    "<$str>"
}


ListAddCommand "wdc" "set $pwd to clipboard"
function wdc(){
    set-clipboard -value "$pwd"
}
ListAddCommand "cwd" "set $pwd to clipboard"
function cwd(){
    wdc
}

ListAddCommand "cdc" "change wd to clipboard value"
function cdc(){
    $clipboard = get-clipboard
    $isDirectory = test-path -path $clipboard -pathtype container
    if(($isDirectory) -eq $false){
        Write-Error "Clipboard is not a directory! - $clipboard"
    } else {
        cd $clipboard
    }
}

ListAddCommand "codec" "open code at clipboard"
function codec(){
    $clipboard = get-clipboard
    $isDirectory = test-path $clipboard
    if(($isDirectory) -eq $false){
        Write-Error "Clipboard is not a path! - $clipboard"
    } else {
        code $clipboard
    }
}

ListAddCommand "clonecdc" "clone repo, cd to dir, open in code"
function clonecdc ([string]$url){
    $directory = clone $url
    cd $directory
    code $directory
}

ListAddCommand "nuke-node-modules" "selectively remove node_modules folders for space"
function nuke-node-modules(){

    $sourceDir = "C:\Dev"

    [regex]$regex = 'node_modules'

    $nodeModules = gci $sourceDir -Recurse -Directory `
        | Where-Object {$_.Name -eq "node_modules"} `
        | Where-Object {(($regex.matches($_.FullName)).Count) -eq 1}

    foreach ($modDir in $nodeModules)
    {
        $dirPath = $modDir.FullName
        $resp = read-host "would like to delete $dirPath ? press y if so."
        if($resp -eq "y"){
            remove-item -Path $dirPath -Recurse
        } else {
            write-host "not deleting $dirPath"
        }
    }

}

ListAddCommand "git-ls" "list untracked files in git (git ls-files --others --exclude-standard)"
function git-ls(){
    git ls-files --others --exclude-standard
}

ListAddCommand "cgb" "copy branch name to clipboard"
function cgb(){
    $branchName = git rev-parse --abbrev-ref HEAD
    set-clipboard -value "$branchName"
}

ListAddCommand "pushf" "first push of branch to origin"
function pushf(){
    $branchName = git rev-parse --abbrev-ref HEAD
    git push origin $branchName --set-upstream
}

