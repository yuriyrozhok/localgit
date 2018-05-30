# ---------------------------------------------------------------------------------------
# Script name:		filerepl.ps1
# Created:			2018-01-09
# Author:			YRO016
# Description:		Replaces the text in all files in all subfolders.
#					You can replace by matching the absolute string or regular expression.
#					IMPORTANT: there is no undo operation, make sure you backup the copy of your files
# Parameters:		
#					dir:
#						Desc: 		input folder - all files including subfolders will be processed
#						Values:		any string
#						Default:	C:\TEMP
#					pattern:
#						Desc: 		pattern to match - can be any text or regular expression
#						Values:		any valid regular expression
#						Default:	DTST16_
#					value:
#						Desc: 		new value for replacement
#						Values:		any string
#						Default:	DPRD_
# Usage example:
#					Matching the absolute string - replace every entry "DTST16_" with "DPRD_":
#					.\fileop\filerepl.ps1 -dir "C:\yrozhok\FBR\database\DTST16_APPL_MSBIPNL" -pattern DTST16_ -value DPRD_
#					Matching the regular expression - replace every DTST16, DTS33
#					.\fileop\filerepl.ps1 -dir C:\Temp\TD -pattern "DTST\d+" -value DPRD
# Links:
#					Recommended reference for building the regular expressions:
#					https://docs.microsoft.com/en-us/dotnet/standard/base-types/regular-expression-language-quick-reference
# ---------------------------------------------------------------------------------------
param(
	[string]$dir = "C:\TEMP", 
	[string]$fmask = "*.sql",
	[string]$pattern = "DTST\d+_",
	[string]$value = "DPRD_"
)
write-host "::: start..."
$fileList = Get-ChildItem $dir -Include $fmask -Recurse
foreach ($file in $fileList) {
	(Get-Content $file.FullName) -replace $pattern, $value | Set-Content $file.FullName
	write-host ("{0}" -f $file.FullName);
}
write-host "::: done."