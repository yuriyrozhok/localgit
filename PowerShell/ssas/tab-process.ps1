[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Tabular") | Out-Null;
#https://docs.microsoft.com/en-us/sql/analysis-services/instances/connection-string-properties-analysis-services
#https://docs.microsoft.com/en-us/sql/analysis-services/tabular-model-programming-compatibility-level-1200/introduction-to-the-tabular-object-model-tom-in-analysis-services-amo
#https://msdn.microsoft.com/en-us/library/microsoft.analysisservices.tabular.server.aspx
#https://docs.microsoft.com/en-us/powershell/module/Microsoft.PowerShell.Utility/Write-Progress?view=powershell-5.1

#[string]$srv_name 	= "asazure://westeurope.asazure.windows.net/msbissas"
#[string]$db_name 	= "DYI"

[string]$srv_name 	= "ADL1\TAB2017"
[string]$db_name 	= "ADL_DYI"

[string]$table_name = "YieldResults"
[string]$user_name	= "Yuriy.Rozhok@maersk.com"
[string]$batchSize 	= 6
[string]$dir 		= "C:\Temp\PROC"
[string]$batch_template = 
'{{"sequence": {{"maxParallelism": {0}, "operations": [
{{"refresh": {{"type": "dataOnly", "objects": [
{1}
]}}}}
]}}}}
'

$server = New-Object Microsoft.AnalysisServices.Tabular.Server
write-host ("::: connecting to SSAS instance: {0} ..." -f $srv_name)
if($srv_name.Substring(0,7) -eq "asazure") {
	write-host "hosted in Azure"
	$connection = ("Data Source={0};UID={1};PWD={2}" -f $srv_name, $user_name, "IMShealth/3")
} else {
	write-host "hosted on premise"
	$connection = ("Data Source={0}" -f $srv_name)
}

$server.connect($connection)
$db = $server.Databases.GetByName($db_name)
write-host("::: db [{0}] size: {1} bytes, state: {2}, tables: {3}" -f $db.Name, $db.EstimatedSize, $db.State, $db.Model.Tables.Count)
$table = $db.Model.Tables.Item($table_name)
write-host("::: table [{0}] partitions: {1}" -f $table_name, $table.Partitions.Count)

$partitionCount = $table.Partitions.Count
$batchCount = [math]::Ceiling($partitionCount / $batchSize)
write-host("::: split {0} partitions into {1} batches, {2} partitions each" -f $partitionCount, $batchCount, $batchSize)

Remove-Item -Path ("{0}\*.json" -f $dir)
$procItemTemplate = '{{"database": "{0}", "table": "{1}", "partition": "{2}"}}'
for ($b = 1; $b -le $batchCount; $b++) {
	$pblock = ""
	for ($i = 1; $i -le $batchSize; $i++) {
		$p = ($b - 1) * $batchSize + $i
		if ($p -le $partitionCount) {
			$partition = $table.Partitions[$p-1]
			$procItem = ($procItemTemplate -f $db.Name, $table.Name, $partition.Name)
			$pblock = ("{0},{1}`r`n" -f $pblock, $procItem)
		}
	}
	$pblock = $pblock.Remove(0,1) #removes the leading comma
	$tmslBatch = $batch_template -f $batchSize, $pblock
	$fname = "{0}_batch_{1:d3}" -f $table_name, $b
	$filepath = ("{0}\{1}.json" -f $dir, $fname)
	set-content -Path $filepath -Value $tmslBatch -Force
	write-host($filepath)
}
write-host("::: Done.")
