# ---------------------------------------------------------------------------------------
# Script name:		dimsrc.ps1
# Created:			2018-05-29
# Author:			YRO016
# Description:		Reads the source views/tables/columns for the cube dimensions.
# ---------------------------------------------------------------------------------------
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null;

[string]$srv_name 	= "SCRBMSBDKBAL220\PRODQUERYSERVER1"
[string]$db_name 	= "FBR_FYPnL_201804_ROFO2"
[string]$cube_name 	= "FYPnL Cube"

$server = New-Object Microsoft.AnalysisServices.Server
write-host ("::: connecting to SSAS instance: {0} ..." -f $srv_name)
$server.connect($srv_name)
$db = $server.Databases.Item($db_name)
write-host("::: database: [{0}]" -f $db.Name)
$cube = $db.Cubes.FindByName($cube_name)
write-host("::: state of the cube [{0}]: {1}" -f $cube.Name, $cube.State)
write-host("::: dimensions:")
foreach ($dim in $cube.Dimensions) {
	write-host("::: dim [{0}]" -f $dim.Name)
}
write-host("::: Done.")
