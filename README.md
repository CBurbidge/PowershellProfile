# PowershellProfile
This is my powershell $profile.

To install this as you profile 

- change the COMPUTERNAME in the AddFilesToProfile. Need to change this to the name of your 'Home' computer as if it doesn't match then it will assume that the work profile needs to be used.
- open up a powershell console window, make sure the execution policy is appropriate.
- cd to where the files are and run the command `powershell -file .AddFilesToProfile.ps1`.

That should work, try again if it doesn't.

Write `editprofile` to bring up the profile in powershell_ise and type `list` to see the commands that are available.
