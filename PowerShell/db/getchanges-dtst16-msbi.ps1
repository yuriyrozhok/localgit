#$codelib = "C:\Users\YRO016\OneDrive - Maersk Group\CodeLib\PowerShell"
#$pulldll = ("{0}\db\pullddl.ps1" -f $codelib)
$pulldll = ".\db\pullddl.ps1"
$dir = "C:\yrozhok\FBR\database\changed\dtst16"
$date = "2018-02-12"

& $pulldll -database DTST16_APPL_MSBISHAR 		-dir $dir -after $date -user YRO016_ADL -fcase L
& $pulldll -database DTST16_APPL_MSBISHAR_PROC 	-dir $dir -after $date -user YRO016_ADL -fcase L
& $pulldll -database DTST16_APPL_MSBISHAR_WRK 	-dir $dir -after $date -user YRO016_ADL -fcase L
& $pulldll -database DTST16_APPL_MSBIPNL 		-dir $dir -after $date -user YRO016_ADL -fcase L
& $pulldll -database DTST16_APPL_MSBIPNL_PROC 	-dir $dir -after $date -user YRO016_ADL -fcase L
& $pulldll -database DTST16_APPL_MSBIPNL_WRK 	-dir $dir -after $date -user YRO016_ADL -fcase L
