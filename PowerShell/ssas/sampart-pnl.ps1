#place this script to the main folder of multidimensional project
#changes partitions to load only sample of data

$codelib = "C:\Users\YRO016\OneDrive - Maersk Group\CodeLib\PowerShell"
$filerepl = ("{0}\fileop\filerepl.ps1" -f $codelib)
$pnldir = "C:\TFS-MSBI\FBR\SSAS_Multi\FBR_ProfitAndLoss\pnl\bin"
$asdb = "FBR_ProfitAndLoss.asdatabase"
$toprows = 1000000
#make sure regex literals are mentioned with \

& $filerepl -dir $pnldir -fmask $asdb -pattern "SELECT \* FROM PnL_FACT" -value ("SELECT TOP {0} * FROM PnL_FACT" -f $toprows)
& $filerepl -dir $pnldir -fmask $asdb -pattern "SELECT \* FROM PnLFACT" -value ("SELECT TOP {0} * FROM PnLFACT" -f $toprows)
& $filerepl -dir $pnldir -fmask $asdb -pattern "SELECT \* FROM FACT_" -value ("SELECT TOP {0} * FROM FACT_" -f $toprows)
& $filerepl -dir $pnldir -fmask $asdb -pattern "SELECT \* FROM PnLContMov" -value ("SELECT TOP {0} * FROM PnLContMov" -f $toprows)
