# ---------------------------------------------------------------------------------------
# Script name:		pullddl.ps1
# Created:			2018-01-09
# Author:			YRO016
# Description:		Downloads the definitions of the database objects and saves to the files.
#					Each object's definition is placed into the separate SQL file.
#					Folders are separated per database/object type.
# Parameters:		
#					database:
#						Desc: 		database name
#						Values:		any string
#						Default:	DPRD_SSL_MDM_V
#					dir:
#						Desc: 		output folder - full path (will be created if not exists)
#						Values:		any string
#						Default:	C:\TEMP\TD
#					after:
#						Desc: 		earliest object modification date
#						Values:		any valid date
#						Default:	1900-01-01
#						Format:		YYYY-MM-DD
#					user:
#						Desc: 		user name who lastly modified the object (or * for any user)
#						Values:		any string
#						Default:	*
#					fcase:
#						Desc: 		file name case
#						Values:		N - natural case, U - upper case, L - lower case
#						Default:	N
# Usage example:
#					.\pullddl.ps1 -database DPRD_APPL_MSBIPNL -dir C:\yrozhok\FBR\database
#					.\db\pullddl.ps1 -database DTST16_APPL_MSBIPNL -dir C:\yrozhok\FBR\database -after 2018-01-03 -user YRO016_ADL
# ---------------------------------------------------------------------------------------
param (
	[string]$database = "DPRD_SSL_MDM_V",
	[string]$dir = "C:\TEMP\TD",
	[string]$after = "1900-01-01",
	[string]$user = "*",
	[string]$fcase = "N"
)
[System.Reflection.Assembly]::LoadWithPartialName("Teradata.Client.Provider") | Out-Null
[string]$connectionString = "Data Source=maersk6;User Id=UADL_BICC_LOADUSER;Password=Lab@BICC123;Connection Timeout=300;"
[string]$SQL = ("SELECT DataBaseName, TableName, TableKind, LastAlterName, LastAlterTimeStamp, RequestText `
FROM dbc.tablesv WHERE databasename='{0}' `
AND (LastAlterName = '{1}' OR '{1}' = '*') `
AND LastAlterTimeStamp > TIMESTAMP '{2} 00:00:00' `
ORDER BY TableName" -f $database, $user, $after)

$connection = new-object Teradata.Client.Provider.TdConnection($connectionString)
$connection.Open()
write-host "::: connection established"

$listcmd = new-object Teradata.Client.Provider.TdCommand($SQL, $connection)
$listcmd.CommandTimeout = 180

$showcmd = new-object Teradata.Client.Provider.TdCommand
$showcmd.Connection = $connection
$showcmd.CommandTimeout = 180

$reader = $listcmd.ExecuteReader()

while ($reader.Read())
{
	$db = $reader["DataBaseName"].ToString().Trim()
	$type = $reader["TableKind"].ToString().Trim()
	$obj = $reader["TableName"].ToString().Trim()
	$fullname = ("{0}.{1}" -f $db, $obj)
	#$text = $reader["RequestText"].ToString() -replace "`r","`r`n" 
	write-host ("{0}: {1}" -f $type, $obj);

	switch($type) {
		'T' {$show = "table"}
		'V' {$show = "view"}
		'M' {$show = "macro"}
		'P' {$show = "procedure"}
		'O' {$show = "table"}
		default {$show = "unknown"}
	}
	
	$type = ("{0}s" -f $show); 
	$subdir = ("{0}\{1}\{2}" -f $dir, $db, $type)
	$filepath = ("{0}\{1}.sql" -f $subdir, $obj)
	switch($fcase) {
		'U' {$subdir = $subdir.ToUpper();$filepath = $filepath.ToUpper()}
		'L' {$subdir = $subdir.ToLower();$filepath = $filepath.ToLower()}
		default {}
	}
	
	$show = ('SHOW {0} {1}' -f $show, $fullname)
	$showcmd.CommandText = $show
	$text = $showcmd.ExecuteScalar().ToString().Trim() -replace "`r","`r`n" -replace "`n`n","`n" 
	
	if(!(test-path $subdir))
	{
		new-item -ItemType Directory -Force -Path $subdir | Out-Null
	}
	set-content -Path $filepath -Value $text -Force
}
$reader.Close()
$listcmd.Dispose()
$showcmd.Dispose()
$connection.Close()
write-host "::: done."

