#changes partitions to load only sample of data

$codelib = "C:\Users\YRO016\OneDrive - Maersk Group\CodeLib\PowerShell"
$filerepl = ("{0}\fileop\filerepl.ps1" -f $codelib)
$asdb = "*.asdatabase"

#make sure regex literals are mentioned with \

& $filerepl -dir .\bin -fmask $asdb -pattern "/\*FCT\*/SELECT" -value "SELECT TOP 1000 "
