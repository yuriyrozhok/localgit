<#
you can run MDX in a simple way, but it's hard to interpret the results as they are in XMLA:
>sqlps
>Invoke-ASCmd -Server ADL2 -Database CYF -Query "select FFE on 0, NonEmptyCrossJoin(Brand.Members, [Equipment].[Equipment Type].Members) on 1 from CYF"  > c:\temp\ASCmd-response3.xml

if you want to invoke this function from the other script, you have to import function from this one:
. .\mdxtest.ps1
ExecuteMDX -connectionString "Data Source=ADL2;Catalog=CYF" -MDX "select FFE on 0, non empty Brand.Members on 1 from CYF"

if you  just want to execute this script:
.\mdxtest.ps1
.\mdxtest.ps1 -configFile loadtest.xml
#>
param(
	[string]$configFile = "loadtest-pnl.xml"
)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.AdomdClient") | Out-Null;
[System.Reflection.Assembly]::LoadWithPartialName("Teradata.Client.Provider") | Out-Null;


[xml]$config = Get-Content $configFile;
function ExecuteMDX {
    param (
         [Parameter(Mandatory=$true)] [string]$connectionString
        ,[Parameter(Mandatory=$true)] [string]$MDX
    )
	#write-host "connecting to $connectionString ..."
	$ds = new-object System.Data.DataSet 
	try {
		$con = new-object Microsoft.AnalysisServices.AdomdClient.AdomdConnection($connectionString) 
		$con.Open() 
		#write-host "connection established"
		
		$command = new-object Microsoft.AnalysisServices.AdomdClient.AdomdCommand($MDX, $con) 
		$dataAdapter = new-object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter($command) 
		
		$dataAdapter.Fill($ds) | Out-Null;
		$con.Close();
	}
	finally {
		$con = $null
	}
	#write-host ("columns:{0}, rows:{1}" -f $ds.Tables[0].Columns.Count, $ds.Tables[0].Rows.Count)
	#$ds.Tables[0] | export-csv -path $CSVFileFullName -Delimiter "," -NoTypeInformation;
	#write-host "done."
	return $ds;
	#.Tables[0];
};

function ExecuteSQL {
    param (
         [Parameter(Mandatory=$true)] [string]$connectionString
        ,[Parameter(Mandatory=$true)] [string]$SQL
    )
	#write-host ("::: SQL connecting to {0} ..." -f $connectionString)

	#[string]$connectionString = "Data Source=maersk6;User Id=UADL_BICC_LOADUSER;Password=Lab@BICC123;Connection Timeout=300;"
	$ds = new-object System.Data.DataSet 
	try {
		$connection = new-object Teradata.Client.Provider.TdConnection($connectionString)
		$connection.Open()
		#write-host "::: connection established"

		$command = new-object Teradata.Client.Provider.TdCommand($SQL, $connection)
		$command.CommandTimeout = 180

		$dataAdapter = new-object Teradata.Client.Provider.TdDataAdapter($command) 
		
		$dataAdapter.Fill($ds) | Out-Null;
	}
	finally {
		$dataAdapter.Dispose()
		$command.Dispose()
		$connection.Close()
	}
	#write-host ("SQL columns: {0}" -f $ds.Tables[0].Columns.Count)
	#write-host ("SQL rows: {0}" -f $ds.Tables[0].Rows.Count)
	
	#write-host "::: SQL done."
	return $ds;
};

function DisplayMatch {
	param(
		[string] $Title,
		[string] $SourceValue,
		[string] $TargetValue
	)
	$not = $(if ($SourceValue -eq $TargetValue) {""} else {" NOT"});
	$title = ("{0}{1} MATCHING" -f $Title, $not);
	$color = $(if ($SourceValue -eq $TargetValue) {"green"} else {"red"});

	write-host ("[{0}] source:{1} target:{2}" -f $title, $SourceValue, $TargetValue) -foregroundcolor $color
};

function ValidateStructure {
	param(
		[parameter(mandatory=$true)] [System.Data.DataTable]$dtSource,
		[parameter(mandatory=$true)] [System.Data.DataTable]$dtTarget
	)
	#$dtSource.GetType();
	write-host ("validating structure...");
	$rcS = $dtSource.Rows.Count
	$rcT = $dtTarget.Rows.Count
	DisplayMatch -Title "ROWS NUMBER" -SourceValue $rcS -TargetValue $rcT;

	$ccS = $dtSource.Columns.Count
	$ccT = $dtTarget.Columns.Count
	DisplayMatch -Title "COLUMNS NUMBER" -SourceValue $ccS -TargetValue $ccT;

	$matching = $true
	foreach($colS in $dtSource.Columns) {
		$colT = $dtTarget.Columns[$colS.Ordinal];
		if ($colS.Caption -ne $colT.Caption) {
			write-host ("[HEADERS NOT MATCHING] source:{0} target:{1}" -f $colS.Caption, $colT.Caption) -foregroundcolor "red";
			#DisplayMatch -Title "COLUMN HEADERS" -SourceValue $colS.Caption -TargetValue $colT.Caption;

			$matching = $false;
			break;
		}
	}
	if ($matching) {
		write-host "[HEADERS MATCHING]" -foregroundcolor "green";
	}
}

function ValidateData {
	param(
		[parameter(mandatory=$true)] [System.Data.DataTable]$dtSource,
		[parameter(mandatory=$true)] [System.Data.DataTable]$dtTarget
	)
	<#
	more info on math: http://www.madwithpowershell.com/2013/10/math-in-powershell.html
	#>
	write-host ("validating data...");
	$precision = $config.suite.config.compare.precision;
	$cols = $dtSource.Columns.Count;
	$rows = $dtSource.Rows.Count;

	$matching = $true
	for ($r = 0; $r -le $rows-1; $r++) {
		for ($c = 0; $c -le $cols-1; $c++) {
			$sval = $dtSource.Rows[$r][$c]
			$tval = $dtTarget.Rows[$r][$c]
			[bool]$isnum = $sval.GetType().Name -match 'float|double' -or $tval.GetType().Name -match 'float|double'
			#note: $null and DBNull are different!
			#this means if result cell contains empty value, it's DBNull and comparison ($sval -eq $null) doesn't work
			[bool]$sisnull = ([DBNull]::Value).Equals($sval)
			[bool]$tisnull = ([DBNull]::Value).Equals($tval)
			#1. no matter what type, both must be empty or both must be not empty
			#2. if not numeric - values should match
			#3. if numeric and not empty - difference should not exceed the defined precision
			if (`
				(($sisnull -and !$tisnull) -or (!$sisnull -and $tisnull)) `
				-or `
				(!$isnum -and ($sval -ne $tval)) `
				-or `
				($isnum -and !$sisnull -and !$tisnull -and [math]::abs($sval - $tval) -ge $precision)`
				) {
				$matching = $false;
				break;
			}
		}
		if (!($matching)) {
			break;
		}
	}
	if ($matching) {
		write-host "[DATA MATCHING]" -foregroundcolor "green";
	} else {
		write-host ("[DATA NOT MATCHING] ({0},{1}) source:{2} target:{3}" -f $r, $c, $sval, $tval) -foregroundcolor "red";
	}
	
}
function ExportDataCSV {
	param(
		[parameter(mandatory=$true)] [System.Data.DataTable]$dt,
		[parameter(mandatory=$true)] [string]$fname
	)
	write-host ("exporting data to {0}..." -f $fname);
	$csv = "{0}\{1}.csv" -f $config.suite.config.export.path, $fname;
	$dt | export-csv -path $csv -Delimiter "," -NoTypeInformation;

}

function ExecuteQuery {
    param (
         [Parameter(Mandatory=$true)] [System.Xml.XmlElement]$connection
        ,[Parameter(Mandatory=$true)] [string]$queryText
    )
	$startTime = Get-Date
	switch($connection.platform) {
		'SSAS' {
			$ds = ExecuteMDX -connectionString $connection.connection -MDX $queryText
		}
		'Teradata' {
			$ds = ExecuteSQL -connectionString $connection.connection -SQL $queryText
		}
		default {}
	}
	$endTime = Get-Date
	$diffTime = New-TimeSpan $startTime $endTime
	write-host ("execution time: {0:G}" -f $diffTime)
	#write-host ("tables: {0}" -f $ds.Tables.Count)
	return $ds
}

function RunReconciliationTests {
	write-host (":::RUNNING RECO TESTS ..." -f $connectionString)

	#[System.Data.DataSet]$ds;
	$date = "{0:yyyyMMdd_HHmmss}" -f (Get-Date)
	[bool]$exp = $config.suite.config.export.enabled -eq "true"
	
	foreach ($test in $config.suite.tests.test) {
		if ($test.enabled -eq "true") {
			write-host ("[EXEC] id:{0}, query:{1}" -f $test.id, $test.query) -foregroundcolor "cyan"
			
			write-host ("executing source: {0}..." -f $config.suite.config.source.connection)
			$dsS = ExecuteQuery -connection $config.suite.config.source -queryText $test.query
			write-host ("executing target: {0}..." -f $config.suite.config.target.connection)
			$dsT = ExecuteQuery -connection $config.suite.config.target -queryText $test.query
			
			ValidateStructure -dtSource $dsS.Tables[0] -dtTarget $dsT.Tables[0]
			ValidateData -dtSource $dsS.Tables[0] -dtTarget $dsT.Tables[0]
			if ($exp) {
				$fname = "{0}_{1:D4}" -f $date, [int]$test.id			
				$fs = ("{0}S" -f $fname)
				$ft = ("{0}T" -f $fname)
				ExportDataCSV -dt $dsS.Tables[0] -fname $fs
				ExportDataCSV -dt $dsT.Tables[0] -fname $ft
			}
		}
	}
	write-host ("::: RECO TESTS DONE.");
}
function RunLoadTests {
	write-host (":::RUNNING LOAD TESTS ..." -f $connectionString)

	$date = "{0:yyyyMMdd_HHmmss}" -f (Get-Date)
	[bool]$exp = $config.suite.config.export.enabled -eq "true"
	write-host ("source: {0}" -f $config.suite.config.source.connection)
	
	foreach ($test in $config.suite.tests.test) {
		if ($test.enabled -eq "true") {
			write-host ("[EXEC] id:{0}, query:{1}" -f $test.id, $test.query) -foregroundcolor "cyan"
			$dsS = ExecuteQuery -connection $config.suite.config.source -queryText $test.query
			if ($exp) {
				$fname = "{0}_{1:D4}" -f $date, [int]$test.id			
				$fs = ("{0}S" -f $fname)
				ExportDataCSV -dt $dsS.Tables[0] -fname $fs
			}
		}
	}
	write-host ("::: LOAD TESTS DONE.");
}

#write-host $config.suite.config.test.type
switch($config.suite.config.test.type) {
	'load' {
		RunLoadTests;
	}
	'reco' {
		RunReconciliationTests;
	}
	default {}
}


#$dsS = ExecuteQuery -connection $config.suite.config.source -queryText "select {[Measures].[Amount USD ShpLvL],[Measures].[FFE Discharged],[Measures].[FFE Loaded]} on 0 from [PnL Cube]"
