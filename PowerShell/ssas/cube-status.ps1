[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null;

[string]$srv_name 	= "SCRBMSBDK000660"
[string]$db_name 	= "FBR_ProfitAndLoss"
[string]$cube_name 	= "PnL Cube"
[string]$dim_name 	= "Time Accounting period"
[string]$attr_name 	= "Month NN 1"


$server = New-Object Microsoft.AnalysisServices.Server
write-host ("::: connecting to SSAS instance: {0} ..." -f $srv_name)
$server.connect($srv_name)
$db = $server.Databases.Item($db_name)
write-host("::: db size of {0}: {1} bytes" -f $db_name, $db.EstimatedSize)

$cube = $db.Cubes.FindByName($cube_name)
write-host("::: state of the cube {0}: {1}" -f $cube_name, $cube.State)

$dim = $cube.Dimensions.FindByName($dim_name)
$attr = $dim.Attributes.Item($attr_name)

write-host("::: attributes in dimension {0}: {1}" -f $dim_name, $dim.Attributes.Count)
write-host("::: attribute hierarchy: {0}" -f $attr.AttributeHierarchyEnabled)
write-host("::: attribute visible: {0}" -f $attr.AttributeHierarchyVisible)

