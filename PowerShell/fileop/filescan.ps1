# ---------------------------------------------------------------------------------------
# Script name:		filescan.ps1
# Created:			2018-01-09
# Author:			YRO016
# Description:		Searches the text in all files in all subfolders.
#					You can seacrh by matching the absolute string or regular expression.
#					The output is the CSV file which can be opened and filtered/analyzed in Excel.
# Parameters:		
#					dir:
#						Desc: 		input folder - all files including subfolders will be scanned
#						Values:		existing folder path
#						Default:	C:\TEMP
#					csv:
#						Desc: 		output file name - all matches will be landing there formatted as CSV
#						Values:		full path to the file - new will be created, existing will be replaced
#						Default:	C:\TEMP
#					pattern:
#						Desc: 		pattern to match - can be any text or regular expression
#						Values:		any valid regular expression
#						Default:	DTST\d+
# Usage example:
#					Matching the absolute string:
#					.\fileop\filescan.ps1 -dir "C:\Temp\TD" -pattern "Service"
#					Matching the regular expression - replace every DTST16, DTS33
#					.\fileop\filescan.ps1 -dir "C:\Temp\TD" -pattern "DTST\d+" -csv C:\Temp\scanresults.csv
# Links:
#					Recommended reference for building the regular expressions:
#					https://docs.microsoft.com/en-us/dotnet/standard/base-types/regular-expression-language-quick-reference
# ---------------------------------------------------------------------------------------

<#
	This script scans the files in all subfolders of the given dir and looks up for the regex pattern entry.
	All matches are written to the CSV report which can be analyzed/filtered in Excel.
#>
param(
	[string]$csv = 'C:\TEMP\filescan.csv', 
	[string]$dir = "C:\TEMP", 
	[string]$pattern = "DTST\d+"
)
$fileList = Get-ChildItem $dir -Include *.sql,*.txt -Recurse
$output =  new-object System.IO.StreamWriter($csv)
$output.WriteLine('Value,Line Number,Line,File Path')
$matches = 0
foreach ($file in $fileList) {
	$input = New-Object System.IO.StreamReader($file)
	$ln = 0
	while (!$input.EndOfStream) {
		$text = $input.ReadLine();
		$ln++;
		foreach ($match in ([regex]$pattern).Matches($text)) {   
			   $output.WriteLine('"{0}",{1},"{2}","{3}"',$match.Value, $ln, $text, $file.fullname)  
			   $matches++;
		}
	}
	$input.close();  
}
$output.close()
write-host ("matches found: {0}" -f $matches)
write-host "::: done."
