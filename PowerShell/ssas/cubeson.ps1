# ---------------------------------------------------------------------------------------
# Script name:		cubeson.ps1
# Created:			2018-05-29
# Author:			YRO016
# Description:		Reads the metadata for SSAS cube objects and generates JSON document.
# Parameters:		
#					server:
#						Desc: 		SSAS server instance
#						Values:		any text
#					database:
#						Desc: 		SSAS database name
#						Values:		any text
#					outfile:
#						Desc: 		output file name
#						Values:		proper file path
# Usage example:
#					document the Pulse database:
# 						.\cubeson.ps1 -server SCRBMSBDK000660 -database FBR_Pulse_SE_DTST18 -outfile C:\FBR\doc\FBR_Pulse_SE_DTST18.json
# ---------------------------------------------------------------------------------------
param (
    [string]$server = "SCRBMSBDK000660",
    [string]$database = "FBR_FYPnL_DPRD",
    [string]$outfile = ".\result.json"
)
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null;

$srv = New-Object Microsoft.AnalysisServices.Server
write-host ("::: connecting to SSAS instance: {0} ..." -f $server)
$srv.connect($server)
$db = $srv.Databases.FindByName($database)
write-host("::: database: [{0}]" -f $db.Name)

function GetDimensionAttributeInfo {
    param (
        [Parameter(Mandatory = $true)] $attr
    )	
    [Microsoft.AnalysisServices.ColumnBinding]$ncb = $attr.NameColumn.Source;	
    $keys = @()
    foreach ($keycol in $attr.KeyColumns) {
        $kcb = $keycol.Source
        $keys += @{
            KeyColumnID      = $kcb.ColumnID
            KeyColumnTableID = $kcb.TableID
        }	
    }
    $attrInfo = @{
        ID                        = $attr.ID
        Name                      = $attr.Name
        IsAggregatable            = $attr.IsAggregatable
        AttributeHierarchyVisible = $attr.AttributeHierarchyVisible
        AttributeHierarchyEnabled = $attr.AttributeHierarchyEnabled
        FriendlyName              = $attr.FriendlyName
        DefaultMember             = $attr.DefaultMember
        KeyColumns                = $keys
        NameColumnID              = $ncb.ColumnID
        NameColumnTableID         = $ncb.TableID
    }
    return $attrInfo
}
function GetDatabaseDimensionAttributes {
    param (
        [Parameter(Mandatory = $true)] $dbdim
    )		
    $attributes = @()
    foreach ($attr in $dbdim.Attributes) {
        $attrInfo = GetDimensionAttributeInfo -attr $attr
        $attributes += $attrInfo
    }
    return $attributes
}

function GetDatabaseDimensionInfo {
    param (
        [Parameter(Mandatory = $true)] $dbdim
    )	
    $attrs = GetDatabaseDimensionAttributes -dbdim $dbdim
    $keyattr = GetDimensionAttributeInfo -attr $dbdim.KeyAttribute
    $dbdimInfo = @{
        ID            = $dbdim.ID
        Name          = $dbdim.Name
        FriendlyName  = $dbdim.FriendlyName
        LastProcessed = '{0:yyyy-MM-dd hh:mm}' -f $dbdim.LastProcessed
        State         = [string]$dbdim.State
        KeyAttribute  = $keyattr
        Attributes    = $attrs
    }
    return $dbdimInfo
}

function GetCubeDimensionInfo {
    param (
        [Parameter(Mandatory = $true)] $cubedim
    )	
    $attrs = GetCubeAttributes -cubedim $cubedim
    $cubedimInfo = @{
        ID           = $cubedim.ID
        Name         = $cubedim.Name
        FriendlyName = $cubedim.FriendlyName
        Attributes   = $attrs
    }
    return $cubedimInfo
}

function GetCubeDimensions {
    param (
        [Parameter(Mandatory = $true)] $cube
    )		
    $dims = @()
    foreach ($dim in $cube.Dimensions) {
        $dimInfo = GetCubeDimensionInfo -cubedim $dim
        $dims += $dimInfo
    }
    return $dims
}
function GetMeasureGroupInfo {
    param (
        [Parameter(Mandatory = $true)] $mgroup
    )	
    $measures = GetMeasures -mgroup $mgroup	
    $partitions = GetPartitions -mgroup $mgroup
    $mgInfo = @{
        ID              = $mgroup.ID
        Name            = $mgroup.Name
        FriendlyName    = $mgroup.FriendlyName
        LastProcessed   = '{0:yyyy-MM-dd hh:mm}' -f $mgroup.LastProcessed
        State           = [string]$mgroup.State
        EstimatedRows   = ("{0:n0}" -f $mgroup.EstimatedRows)
        EstimatedSizeMB = ("{0:n2}" -f ($mgroup.EstimatedSize / 1024 / 1024))
        Measures        = $measures
        Partitions      = $partitions
    }
    return $mgInfo
}
function GetMeasureGroups {
    param (
        [Parameter(Mandatory = $true)] $cube
    )		
    $mgroups = @()
    foreach ($mgroup in $cube.MeasureGroups) {
        $mgInfo = GetMeasureGroupInfo -mgroup $mgroup
        $mgroups += $mgInfo
    }
    return $mgroups
}

function GetMeasureInfo {
    param (
        [Parameter(Mandatory = $true)] $measure
    )		
    $measureInfo = @{
        ID                = $measure.ID
        Name              = $measure.Name
        FriendlyName      = $measure.FriendlyName
        AggregateFunction = [string]$measure.AggregateFunction
        DataType          = [string]$measure.DataType
        DisplayFolder     = $measure.DisplayFolder
        FormatString      = $measure.FormatString
        Visible           = $measure.Visible
        FriendlyPath      = $measure.FriendlyPath
        SourceColumnID    = $measure.Source.ColumnID
        SourceTableID     = $measure.Source.TableID
        DataSize          = $measure.Source.DataSize
    }
    return $measureInfo
}
function GetMeasures {
    param (
        [Parameter(Mandatory = $true)] $mgroup
    )		
    $measures = @()
    foreach ($measure in $mgroup.Measures) {
        $measureInfo = GetMeasureInfo -measure $measure
        $measures += $measureInfo
    }
    return $measures
}

function GetPartitionInfo {
    param (
        [Parameter(Mandatory = $true)] $part
    )		
    [Microsoft.AnalysisServices.TabularBinding]$bin = $part.Source

    if ($bin -is [Microsoft.AnalysisServices.QueryBinding]) {
        $binding = "QueryBinding"
        $qb = [Microsoft.AnalysisServices.QueryBinding]$bin
        $dsID = $qb.DataSourceID
        $qdef = $qb.QueryDefinition
    }
    elseif ($bin -is [Microsoft.AnalysisServices.TableBinding]) {
        $binding = "TableBinding"
        $tb = [Microsoft.AnalysisServices.TableBinding]$bin
        $dsID = $tb.DataSourceID
        $schema = $tb.DbSchemaName
        $table = $tb.DbTableName
    }
    elseif ($bin -is [Microsoft.AnalysisServices.DsvTableBinding]) {
        $binding = "DsvTableBinding"
        $dsvb = [Microsoft.AnalysisServices.DsvTableBinding]$bin
        $dsvID = $dsvb.DataSourceViewID
        $tableID = $dsvb.TableID
    }
    else {
        $binding = "Unknown"
    }
    $partInfo = @{
        ID               = $part.ID
        Name             = $part.Name
        FriendlyName     = $part.FriendlyName
        Slice            = $part.Slice
        Binding          = $binding
        DataSourceID     = $dsID
        QueryDefinition  = $qdef
        DbSchemaName     = $schema
        DbTableName      = $table
        DataSourceViewID = $dsvID
        TableID          = $tableID
        LastProcessed    = '{0:yyyy-MM-dd hh:mm}' -f $part.LastProcessed
        State            = [string]$part.State
        EstimatedRows    = ("{0:n0}" -f $part.EstimatedRows)
        EstimatedSizeMB  = ("{0:n2}" -f ($part.EstimatedSize / 1024 / 1024))
    }
    return $partInfo
}
function GetPartitions {
    param (
        [Parameter(Mandatory = $true)] $mgroup
    )		
    $partitions = @()
    foreach ($part in $mgroup.Partitions) {
        $partInfo = GetPartitionInfo -part $part
        $partitions += $partInfo
    }
    return $partitions
}

function GetCubeInfo {
    param (
        [Parameter(Mandatory = $true)] $cube
    )		
    $dims = GetCubeDimensions -cube $cube
    $mgroups = GetMeasureGroups -cube $cube
    $cubeInfo = @{
        ID             = $cube.ID
        Name           = $cube.Name
        FriendlyName   = $cube.FriendlyName
        LastProcessed  = '{0:yyyy-MM-dd hh:mm}' -f $cube.LastProcessed
        State          = [string]$cube.State
        DefaultMeasure = $cube.DefaultMeasure
        CubeDimensions = $dims
        MeasureGroups  = $mgroups
    }
    return $cubeInfo
}
function GetCubes {
    param (
        [Parameter(Mandatory = $true)] $database
    )		
    $cubes = @()
    foreach ($cube in $database.Cubes) {
        $cubeInfo = GetCubeInfo -cube $cube
        $cubes += $cubeInfo
    }
    return $cubes
}
function GetDatabaseInfo {
    param (
        [Parameter(Mandatory = $true)] $database
    )		
    $dsvInfo = GetDsvInfo -database $database
    $dsInfo = GetDataSourceInfo -database $database
    $cubes = GetCubes -database $database
    $dbInfo = @{
        ID              = $database.ID
        Name            = $database.Name
        FriendlyName    = $database.FriendlyName
        LastProcessed   = '{0:yyyy-MM-dd hh:mm}' -f $database.LastProcessed
        State           = [string]$database.State
        EstimatedSizeMB = ("{0:n2}" -f ($database.EstimatedSize / 1024 / 1024))
        Cubes           = $cubes
        DataSources     = $dsInfo
        DataSourceViews = $dsvInfo
    }
    return $dbInfo
}

function GetCubeAttributeInfo {
    param (
        [Parameter(Mandatory = $true)] $attr
    )	
    $dimattr = GetDimensionAttributeInfo -attr $attr.Attribute
    $attrInfo = @{
        AttributeHierarchyVisible = $attr.AttributeHierarchyVisible
        AttributeHierarchyEnabled = $attr.AttributeHierarchyEnabled
        FriendlyName              = $attr.FriendlyName
        DimensionAttribute        = $dimattr
    }
    return $attrInfo
}

function GetCubeAttributes {
    param (
        [Parameter(Mandatory = $true)] $cubedim
    )		
    $attributes = @()
    foreach ($attr in $cubedim.Attributes) {
        $attrInfo = GetCubeAttributeInfo -attr $attr
        $attributes += $attrInfo
    }
    return $attributes
}

function GetTableProperty {
    param (
        [Parameter(Mandatory = $true)] $table
        , [Parameter(Mandatory = $true)] [string]$propertyName
    )		
    return $table.ExtendedProperties[$propertyName]
}
function FindTableByID {
    param (
        [Parameter(Mandatory = $true)] [string]$tableID
    )		
    [System.Data.DataTable]$dt = $schema.Tables[$tableID]
    return $dt
}
function GetTableInfo {
    param (
        [Parameter(Mandatory = $true)] $table
	   )
	   $islog = GetTableProperty -table $table -propertyName "IsLogical"
	   if ($islog -eq $null) {$islog = "False"}
    return @{
        ID              = $table.TableName
        IsLogical       = $islog
        FriendlyName    = GetTableProperty -table $table -propertyName "FriendlyName"
        TableType       = GetTableProperty -table $table -propertyName "TableType"
        DbTableName     = GetTableProperty -table $table -propertyName "DbTableName"
        DbSchemaName    = GetTableProperty -table $table -propertyName "DbSchemaName"
        QueryDefinition = GetTableProperty -table $table -propertyName "QueryDefinition"
    }
}
<#	this way we could generate table info dynamically:
	foreach ($extkey in $dt.ExtendedProperties.Keys) {
		$extval = $dt.ExtendedProperties[$extkey]
		write-host("[{0}]=[{1}]" -f $extkey, $extval)
	}
#>	

function GetSchemaInfo {
    param (
        [Parameter(Mandatory = $true)] $dsv
    )		
    $schemaInfo = @()
    foreach ($dt in $dsv.Schema.Tables) {
        $tabInfo = GetTableInfo -table $dt
        $schemaInfo += $tabInfo
    }
    return $schemaInfo
}

function GetDsvInfo {
    param (
        [Parameter(Mandatory = $true)] $database
    )		
    $dsvInfo = @()
    foreach ($dsv in $database.DataSourceViews) {
        $schemaInfo = GetSchemaInfo -dsv $dsv
        $dsvInfo += @{
            ID           = $dsv.ID
            Name         = $dsv.Name
            DataSourceID = $dsv.DataSourceID
            Schema       = $schemaInfo
        }
    }
    return $dsvInfo
}

function GetDataSourceInfo {
    param (
        [Parameter(Mandatory = $true)] $database
    )		
    $dsInfo = @()
    foreach ($ds in $database.DataSources) {
        $dsInfo += @{
            ID               = $ds.ID
            Name             = $ds.Name
            ConnectionString = $ds.ConnectionString
        }
    }
    return $dsInfo
}


$dbInfo = GetDatabaseInfo -database $db
$text = $dbInfo | ConvertTo-Json -Depth 20
set-content -Path $outfile -Value $text -Force

write-host("::: Done.")
