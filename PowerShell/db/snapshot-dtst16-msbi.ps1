$pulldll = ".\db\pullddl.ps1"
$dir = "C:\yrozhok\FBR\database\dtst16"

& $pulldll -database DTST16_APPL_MSBISHAR -dir $dir
& $pulldll -database DTST16_APPL_MSBISHAR_PROC -dir $dir
& $pulldll -database DTST16_APPL_MSBISHAR_SRC -dir $dir
& $pulldll -database DTST16_APPL_MSBISHAR_SRC_V -dir $dir
& $pulldll -database DTST16_APPL_MSBISHAR_WRK -dir $dir
                           
& $pulldll -database DTST16_APPL_MSBIPNL -dir $dir
& $pulldll -database DTST16_APPL_MSBIPNL_PROC -dir $dir
& $pulldll -database DTST16_APPL_MSBIPNL_WRK -dir $dir
                           
& $pulldll -database DTST16_APPL_MSBIFBRPL -dir $dir
& $pulldll -database DTST16_APPL_MSBIFBRPL_PROC -dir $dir
& $pulldll -database DTST16_APPL_MSBIFBRPL_SRC -dir $dir
& $pulldll -database DTST16_APPL_MSBIFBRPL_V -dir $dir
& $pulldll -database DTST16_APPL_MSBIFBRPL_WRK -dir $dir
