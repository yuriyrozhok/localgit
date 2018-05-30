=========================================================================
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                       *
*                        PowerShell Code Library                        *
*                                                                       *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
=========================================================================

* * * * * * * * * * * * * * *  F.   A.   Q. * * * * * * * * * * * * * * *

Q.	How should I run PowerShell scripts?
A.	Do the following steps:
		1. Start "Windows PowerShell" from Start menu
		2. Navigate to the folder where the script is located (e.g. "cd C:\Scripts")
		3. Run the script with this command: ".\scriptname.ps1"
------------------------------------------------------------------------------------------------------------------------
Q.	When running the script I get the error like: 
		<script> cannot be loaded. The file is not digitally signed. You cannot run this script on the current system.
	What should I do?
A.	You have to change the PowerShell security policy on your machine, for this run this command from PowerShell console:
		Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
	This way your system will require only external scripts (downloaded from the Internet) to be signed.
------------------------------------------------------------------------------------------------------------------------
Q.	How can I check my current PS version?
A.	Use "get-host" command
------------------------------------------------------------------------------------------------------------------------
Q.	Why PS scripts have ".ps1" extension - is it compatible with PS 1.0 only?
A.	No, it was only MS initial intention to make scripts version-dependent, but later they refused from this idea.
	Later ".ps1" became the only official extension for all PS scripts, no matter which version they were created for.
	There is no ".ps2" (or ".ps3" etc.) extensions in PowerShell world.
	Basicaly, each version of PS supports the scripts created for previous versiosn.
	You can safely execute ".ps1" scripts in your PS environment. Also name your new scripts using ".ps1" as standard 
	extension.
------------------------------------------------------------------------------------------------------------------------
Q.	How to check my current version of PowerShell?
A.	$PSVersionTable
------------------------------------------------------------------------------------------------------------------------
Q.	Which version of PowerShell I need if I want the latest one?
A.	https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell
------------------------------------------------------------------------------------------------------------------------
Q.	How to check what .NET Framework versions are installed?
A.	https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
------------------------------------------------------------------------------------------------------------------------
Q.	What PS modules are installed?
A.	Get-Module -ListAvailable
------------------------------------------------------------------------------------------------------------------------
Q.	How to check the version of the module?
A.	Get-Module AzureRM -list 
------------------------------------------------------------------------------------------------------------------------
Q.	How I can install new module to my PS?
A.	Install-Module AzureRM
------------------------------------------------------------------------------------------------------------------------
Q.	How to read/write from/to files in PowerShell
A.	Very good summary is here: https://kevinmarquette.github.io/2017-03-18-Powershell-reading-and-saving-data-to-files/
	In general there are two ways:
	- "PS-native":
		- Get-Content - reads from file
		- Set-Content - writes to file
	- C#-like using file streams
		- [IO.File]::ReadAllText($file) (or use System.IO.StreamReader)
		- [IO.File]::WriteAllText($file.FullName, $text) (or use System.IO.StreamWriter)
	Note, there is the difference of wheter you use parentheses or not:
	(Get-Content $file.FullName) | Set-Content $file.FullName - first reads everything and then pipelines to the next operator
	(Get-Content $file.FullName | Set-Content $file.FullName - pipelines line-by-line
------------------------------------------------------------------------------------------------------------------------
Install-Module AzureRM -AllowClobber