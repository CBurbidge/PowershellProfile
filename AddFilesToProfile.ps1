$sharedFileName = "ProfileShared.ps1"
$machineSpecificFileHome = "ProfileHome.ps1"
$machineSpecificFileWork = "ProfileWork.ps1"
$laptopName = "COMPUTERNAME"

# Assign file names, assuming they exist.
$addFile = Get-Item -Path ($MyInvocation.MyCommand.Path)
$workingDir = $addFile.Directory.FullName
"Working dir is - '$workingDir'"
$sharedFile = "$workingDir\$sharedFileName"
"Shared file located at - '$sharedFile'"

if($ENV:ComputerName -eq $laptopName) { 
    $machineSpecificFile = "$workingDir\$machineSpecificFileHome" 
} else { 
    $machineSpecificFile = "$workingDir\$machineSpecificFileWork" 
}
"machineSpecificFile is $machineSpecificFile"


# Ensure profile file exists and do a timestamped backup copy if it already does.
if((Test-Path $profile) -eq $false) {
    "creating profile file" 
    New-Item -path $profile -type file –force 
} else {
    $dateSuffix = (Get-Date).ToString("s").Replace(":","")
    $backupFile = "$profile.backup.$dateSuffix"
    "copying file $profile to $backupFile for backup"
    cp "$profile" $backupFile
}

# Add files to call to editprofile in $profile file and also 
"" > $profile

". `"$sharedFile`""  >> $profile
". `"$machineSpecificFile`""  >> $profile

"`"'editprofile' - edit profile`"" >> $profile
"function editprofile { " >> $profile 
"    powershell_ise `"$sharedFile`" " >> $profile 
"    powershell_ise `"$machineSpecificFile`" " >> $profile 
"}" >> $profile

# cd to $startingDir directory set in other files
"cd `"`$startingDir`"" >> $profile