# ---------------------------------------------------------------------------------------
# Script name:		pullddl.ps1
# Created:			2018-03-15
# Author:			YRO016
# Description:		Fixes the PnL cube structure for enabling it for Power BI access.
#					This requires updates to the definition of [Month NN] attribute.
# ---------------------------------------------------------------------------------------
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null;

[string]$srv_name 	= "SCRBSPSDEFRM607\testqueryserver2"
[string]$db_name 	= "FBR_ProfitAndLoss_YRO016"
[string]$cube_name 	= "PnL Cube"
[string]$attr_name 	= "Month NN 1"
[string[]]$dims = @(
	 "Time Activity period"
	,"Time Loading period"
	,"Time Receipt period"
	,"Time Delivery period"
	,"Time Discharge period"
)

$server = New-Object Microsoft.AnalysisServices.Server
write-host ("::: connecting to SSAS instance: {0} ..." -f $srv_name)
$server.connect($srv_name)
$db = $server.Databases.Item($db_name)
write-host("::: database: [{0}]" -f $db.Name)
$cube = $db.Cubes.FindByName($cube_name)
write-host("::: state of the cube [{0}]: {1}" -f $cube.Name, $cube.State)

foreach ($dim_name in $dims) {
	$dim = $cube.Dimensions.FindByName($dim_name)
	$attr = $dim.Attributes.Item($attr_name)
	write-host("::: attribute hierarchy [{0}].[{1}] enabled: {2}" -f 
		$dim.Name, $attr.Attribute.Name, $attr.AttributeHierarchyEnabled)
	write-host (">>> ::: enabling attribute hierarchy {0} for dimension {1} ..." -f 
		$attr_name, $dim_name)
	$attr.AttributeHierarchyEnabled = $true		
}
write-host("::: updating the cube ...")
$cube.Update()
$db.Update()
write-host("::: cube update done.")
foreach ($dim_name in $dims) {
	$dim = $cube.Dimensions.FindByName($dim_name)
	$attr = $dim.Attributes.Item($attr_name)
	write-host("::: attribute hierarchy [{0}].[{1}] enabled: {2}" -f 
		$dim.Name, $attr.Attribute.Name, $attr.AttributeHierarchyEnabled)
}
