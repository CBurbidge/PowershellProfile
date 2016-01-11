$window = $Host.UI.RawUI
$window.BackgroundColor = "black"
cls

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
    ForEach($listCommand in $profileList.Keys)
    {
        $listInfo = $profileList[$listCommand]
        "- $listCommand `t`t$listInfo"
    }
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

AddUrl "fb" "https://www.facebook.com"
AddUrl "wtf" "http://thedailywtf.com/"
AddUrl "gh" "https://github.com/CBurbidge/"

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

$profilePlaces = @{}
function AddPlace
{
    param([string]$name, [string]$location)
    $profilePlaces[$name] = $location
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

ListAddCommand "go" "'go' - cd to a commonly used place - use 'go list' for places"
function go
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
