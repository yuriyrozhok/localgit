# ---------------------------------------------------------------------------------------
# Script name:   metacube.ps1
# Created:       2018-05-29
# Author:        YRO016
# Description:   Reads the metadata for SSAS cube objects and generates JSON document.
# Parameters:
#                -server      : SSAS server instance
#                -database    : SSAS database name
#                -skipdynamic : once provided, no dynamic data is collected (Processing, State, etc.)
# Output:
#                /output:    this folder should exist, here two files are created:
#                  <database>.amo.json - generates full AMO hierarchy of cube objects
#                  <database>.rdb.json - generates relational structure with foreighn keys
# Notes:
#                skipdynamic parameter is useful for comparison purposes (test vs. prod, etc.)
# Usage example:
#                document the Pulse database:
#                  .\metacube.ps1 -server SCRBMSBDK000660 -database FBR_Pulse_SE_DTST18
#                document the FY PnL database:
#                  .\metacube.ps1 -server SCRBMSBDK000660 -database FBR_FYPnL -skipdynamic
# ---------------------------------------------------------------------------------------
# PS classes: https://xainey.github.io/2016/powershell-classes-and-concepts/#class-structure
param (
    [string]$server = "SCRBMSBDK000660",
    [string]$database = "FBR_Pulse_SE_DTST18",
    [switch]$skipdynamic
)
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null;

$Host.PrivateData.ProgressBackgroundColor = 'Green'
$Host.PrivateData.ProgressForegroundColor = 'White'

$srv = New-Object Microsoft.AnalysisServices.Server
write-host ("::: connecting to SSAS instance: {0} ..." -f $server)
$srv.connect($server)
write-host ("::: connected.")
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
        ID           = $dbdim.ID
        Name         = $dbdim.Name
        FriendlyName = $dbdim.FriendlyName
        KeyAttribute = $keyattr
        Attributes   = $attrs
    }
    if (!$skipdynamic) {
        $dbdimInfo.LastProcessed = '{0:yyyy-MM-dd hh:mm}' -f $dbdim.LastProcessed
        $dbdimInfo.State = [string]$dbdim.State
    }
    return $dbdimInfo
}

function GetCubeDimensionInfo {
    param (
        [Parameter(Mandatory = $true)] $cubedim
    )
    $attrs = GetCubeAttributes -cubedim $cubedim
    $dbdim = GetDatabaseDimensionInfo -dbdim $cubedim.Dimension
    $cubedimInfo = @{
        ID                = $cubedim.ID
        Name              = $cubedim.Name
        FriendlyName      = $cubedim.FriendlyName
        DatabaseDimension = $dbdim
        Attributes        = $attrs
    }
    return $cubedimInfo
}

function GetCubeDimensions {
    param (
        [Parameter(Mandatory = $true)] $cube
    )
    write-host ("::: collecting dimensions of cube [{0}]..." -f $cube.Name)
    $cnt, $idx = $cube.Dimensions.Count, 0
    $dims = @()
    foreach ($dim in $cube.Dimensions) {
        $dimInfo = GetCubeDimensionInfo -cubedim $dim
        $dims += $dimInfo
        write-progress -activity ("Collecting dimensions of cube [{0}]..." -f $cube.Name) `
            -status "Progress:" -percentcomplete (++$idx / $cnt * 100)
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
        ID           = $mgroup.ID
        Name         = $mgroup.Name
        FriendlyName = $mgroup.FriendlyName
        Measures     = $measures
        Partitions   = $partitions
    }
    if (!$skipdynamic) {
        $mgInfo.EstimatedRows = ("{0:n0}" -f $mgroup.EstimatedRows)
        $mgInfo.EstimatedSizeMB = ("{0:n2}" -f ($mgroup.EstimatedSize / 1024 / 1024))
        $mgInfo.LastProcessed = '{0:yyyy-MM-dd hh:mm}' -f $mgroup.LastProcessed
        $mgInfo.State = [string]$mgroup.State
    }
    return $mgInfo
}
function GetMeasureGroups {
    param (
        [Parameter(Mandatory = $true)] $cube
    )
    write-host ("::: collecting measure groups of cube [{0}]..." -f $cube.Name)
    $cnt, $idx = $cube.MeasureGroups.Count, 0
    $mgroups = @()
    foreach ($mgroup in $cube.MeasureGroups) {
        $mgInfo = GetMeasureGroupInfo -mgroup $mgroup
        $mgroups += $mgInfo
        write-progress -activity ("Collecting measure groups of cube [{0}]..." -f $cube.Name) `
            -status "Progress:" -percentcomplete (++$idx / $cnt * 100)
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
    }
    if (!$skipdynamic) {
        $partInfo.EstimatedRows = ("{0:n0}" -f $part.EstimatedRows)
        $partInfo.EstimatedSizeMB = ("{0:n2}" -f ($part.EstimatedSize / 1024 / 1024))
        $partInfo.LastProcessed = '{0:yyyy-MM-dd hh:mm}' -f $part.LastProcessed
        $partInfo.State = [string]$part.State
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
        DefaultMeasure = $cube.DefaultMeasure
        CubeDimensions = $dims
        MeasureGroups  = $mgroups
    }
    if (!$skipdynamic) {
        $cubeInfo.LastProcessed = '{0:yyyy-MM-dd hh:mm}' -f $cube.LastProcessed
        $cubeInfo.State = [string]$cube.State
    }
    return $cubeInfo
}
function GetCubes {
    param (
        [Parameter(Mandatory = $true)] $database
    )
    $cubes = @()
    foreach ($cube in $database.Cubes) {
        write-host ("::: collecting metadata from cube {0}..." -f $cube.Name)
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
        Cubes           = $cubes
        DataSources     = $dsInfo
        DataSourceViews = $dsvInfo
    }
    if (!$skipdynamic) {
        $dbInfo.LastProcessed = '{0:yyyy-MM-dd hh:mm}' -f $database.LastProcessed
        $dbInfo.State = [string]$database.State
        $dbInfo.EstimatedSizeMB = ("{0:n2}" -f ($database.EstimatedSize / 1024 / 1024))
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

function GetSchemaInfo {
    param (
        [Parameter(Mandatory = $true)] $dsv
    )
    write-host ("::: collecting DSV schema of [{0}]..." -f $dsv.Name)
    $cnt, $idx = $dsv.Schema.Tables.Count, 0
    $schemaInfo = @()
    foreach ($dt in $dsv.Schema.Tables) {
        $tabInfo = GetTableInfo -table $dt
        $schemaInfo += $tabInfo
        write-progress -activity ("Collecting schema of DSV [{0}]" -f $dsv.Name) `
            -status "Progress:" -percentcomplete (++$idx / $cnt * 100)
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

function GetTableList {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $tabList = @()
    foreach ($dsv in $dbinfo.DataSourceViews) {
        foreach ($tab in $dsv.Schema) {
            $tabList += @{
                DsvID                = $dsv.ID
                DsvName              = $dsv.Name
                DsvDataSourceID      = $dsv.DataSourceID
                TableID              = $tab.ID
                TableIsLogical       = $tab.IsLogical
                TableFriendlyName    = $tab.FriendlyName
                TableTableType       = $tab.TableType
                TableDbTableName     = $tab.DbTableName
                TableDbSchemaName    = $tab.DbSchemaName
                TableQueryDefinition = $tab.QueryDefinition

            }
        }
    }
    return $tabList
}

function GetCubeList {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $list = @()
    foreach ($cube in $dbinfo.Cubes) {
        $map = @{
            CubeID             = $cube.ID
            CubeName           = $cube.Name
            CubeFriendlyName   = $cube.FriendlyName
            CubeDefaultMeasure = $cube.DefaultMeasure
        }
        if (!$skipdynamic) {
            $map.CubeLastProcessed = $cube.LastProcessed
            $map.CubeState = $cube.State
        }
        $list += $map
    }
    return $list
}

function GetDimensionList {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $list = @()
    foreach ($cube in $dbinfo.Cubes) {
        foreach ($dim in $cube.CubeDimensions) {
            $map = @{
                CubeID                        = $cube.ID
                CubeDimensionID               = $dim.ID
                CubeDimensionName             = $dim.Name
                CubeDimensionFriendlyName     = $dim.FriendlyName
                DatabaseDimensionID           = $dim.DatabaseDimension.ID
                DatabaseDimensionName         = $dim.DatabaseDimension.Name
                DatabaseDimensionFriendlyName = $dim.DatabaseDimension.FriendlyName
                DatabaseDimensionKeyAttribute = $dim.DatabaseDimension.KeyAttribute.ID              
            }
            if (!$skipdynamic) {
                $map.DatabaseDimensionLastProcessed = $dim.DatabaseDimension.LastProcessed
                $map.DatabaseDimensionState = $dim.DatabaseDimension.State
            }
            $list += $map
        }
    }
    return $list
}

function GetAttributeList {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $list = @()
    foreach ($cube in $dbinfo.Cubes) {
        foreach ($dim in $cube.CubeDimensions) {
            foreach ($attr in $dim.Attributes) {
                $map = @{
                    CubeID                        = $cube.ID
                    CubeDimensionID               = $dim.ID
                    CubeAttributeHierarchyVisible = $attr.AttributeHierarchyVisible
                    CubeAttributeHierarchyEnabled = $attr.AttributeHierarchyEnabled
                    CubeAttributeFriendlyName     = $attr.FriendlyName
                    DimAttributeID                = $attr.DimensionAttribute.ID
                    DimAttributeName              = $attr.DimensionAttribute.Name
                    DimAttributeIsAggregatable    = $attr.DimensionAttribute.IsAggregatable
                    DimAttributeHierarchyVisible  = $attr.DimensionAttribute.AttributeHierarchyVisible
                    DimAttributeHierarchyEnabled  = $attr.DimensionAttribute.AttributeHierarchyEnabled
                    DimAttributeFriendlyName      = $attr.DimensionAttribute.FriendlyName
                    DimAttributeDefaultMember     = $attr.DimensionAttribute.DefaultMember
                    DimAttributeNameColumnID      = $attr.DimensionAttribute.NameColumnID
                    DimAttributeNameColumnTableID = $attr.DimensionAttribute.NameColumnTableID
                }
                $kid = 1
                foreach ($key in $attr.DimensionAttribute.KeyColumns) {
                    $map.Add(("KeyColumnID{0}" -f $kid), $key.KeyColumnID)
                    $map.Add(("KeyColumnTableID{0}" -f $kid), $key.KeyColumnTableID)
                    $kid++
                }
                $list += $map
            }
        }
    }
    return $list
}


function GetMeasureGroupList {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $list = @()
    foreach ($cube in $dbinfo.Cubes) {
        foreach ($mg in $cube.MeasureGroups) {
            $map = @{
                CubeID                   = $cube.ID
                MeasureGroupID           = $mg.ID
                MeasureGroupName         = $mg.Name
                MeasureGroupFriendlyName = $mg.FriendlyName
            }
            if (!$skipdynamic) {
                $map.MeasureGroupEstimatedSizeMB = $mg.EstimatedSizeMB
                $map.MeasureGroupEstimatedRows = $mg.EstimatedRows
                $map.MeasureGroupLastProcessed = $mg.LastProcessed
                $map.MeasureGroupState = $mg.State
            }
            $list += $map
        }
    }
    return $list
}

function GetPartitionList {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $list = @()
    foreach ($cube in $dbinfo.Cubes) {
        foreach ($mg in $cube.MeasureGroups) {
            foreach ($part in $mg.Partitions) {
                $map = @{
                    CubeID                    = $cube.ID
                    MeasureGroupID            = $mg.ID
                    PartitionID               = $part.ID
                    PartitionName             = $part.Name
                    PartitionFriendlyName     = $part.FriendlyName
                    PartitionSlice            = $part.Slice
                    PartitionBinding          = $part.Binding
                    PartitionDataSourceID     = $part.DataSourceID
                    PartitionQueryDefinition  = $part.QueryDefinition
                    PartitionDbSchemaName     = $part.DbSchemaName
                    PartitionDbTableName      = $part.DbTableName
                    PartitionDataSourceViewID = $part.DataSourceViewID
                    PartitionTableID          = $part.TableID
                }
                if (!$skipdynamic) {
                    $map.PartitionEstimatedRows = $part.EstimatedRows
                    $map.PartitionEstimatedSizeMB = $part.EstimatedSizeMB
                    $map.PartitionLastProcessed = $part.LastProcessed
                    $map.PartitionState = $part.State
                }
                $list += $map
            }
        }
    }
    return $list
}

function GetMeasureList {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $list = @()
    foreach ($cube in $dbinfo.Cubes) {
        foreach ($mg in $cube.MeasureGroups) {
            foreach ($msr in $mg.Measures) {
                $list += @{
                    CubeID                   = $cube.ID
                    MeasureGroupID           = $mg.ID
                    MeasureID                = $msr.ID
                    MeasureName              = $msr.Name
                    MeasureFriendlyName      = $msr.FriendlyName
                    MeasureAggregateFunction = $msr.AggregateFunction
                    MeasureDataType          = $msr.DataType
                    MeasureDisplayFolder     = $msr.DisplayFolder
                    MeasureFormatString      = $msr.FormatString
                    MeasureVisible           = $msr.Visible
                    MeasureFriendlyPath      = $msr.FriendlyPath
                    MeasureSourceColumnID    = $msr.SourceColumnID
                    MeasureSourceTableID     = $msr.SourceTableID
                    MeasureDataSize          = $msr.DataSize
                }
            }
        }
    }
    return $list
}

function GetBusMatrixList {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $list = @()
    foreach ($cube in $dbinfo.Cubes) {
        foreach ($mg in $cube.MeasureGroups) {
            
        }
    }
    <#
                MeasureGroup mg = cube.MeasureGroups.FindByName(mg_name);
                //MeasureGroupDimension mgd = mg.Dimensions[0];
                MeasureGroupDimension mgd = mg.Dimensions.Find("Order Date Key - Dim Time");
                List<MeasureGroupAttribute> alist = new List<MeasureGroupAttribute>();

                if (mgd is RegularMeasureGroupDimension) {
                    RegularMeasureGroupDimension rmgd = (RegularMeasureGroupDimension) mgd;
                    foreach (MeasureGroupAttribute mgattr in rmgd.Attributes)
                    {
                        if (mgattr.Type == MeasureGroupAttributeType.Granularity)
                        {
                            alist.Add(mgattr);
                        }
                    }
                    //MeasureGroupAttribute mgattr = rmgd.Attributes.f["Key"];
                }

                //MeasureGroupAttribute.Attribute.KeyColumns means dimension binding
                DimensionAttribute da = alist[0].Attribute;
                ColumnBinding dcb = (ColumnBinding)da.KeyColumns[0].Source;
                //dcb.ColumnID, dcb.TableID - dimension columns

                //Type t = alist[0].KeyColumns[0].Source.GetType();
                //MeasureGroupAttribute.KeyColumns means measure group binding
                DataItem kc = alist[0].KeyColumns[0]; 
                ColumnBinding mgcb = (ColumnBinding) alist[0].KeyColumns[0].Source;

                //mgcb.ColumnID, mgcb.TableID - fact table columns
    
    #>

    return $list
}
function GetDatabaseFlat {
    param (
        [Parameter(Mandatory = $true)] $dbinfo
    )
    $tablist = GetTableList -dbinfo $dbInfo
    $cubelist = GetCubeList -dbinfo $dbInfo
    $dimlist = GetDimensionList -dbinfo $dbInfo
    $attrlist = GetAttributeList -dbinfo $dbInfo
    $mglist = GetMeasureGroupList -dbinfo $dbInfo
    $partlist = GetPartitionList -dbinfo $dbInfo
    $msrlist = GetMeasureList -dbinfo $dbInfo
    $dbFlat = @{
        DataSources   = $dbinfo.DataSources
        Tables        = $tablist
        Cubes         = $cubelist
        Attributes    = $attrlist
        Dimensions    = $dimlist
        MeasureGroups = $mglist
        Partitions    = $partlist
        Measures      = $msrlist
    }
    return $dbFlat
}
[string]$treefile = (".\output\{0}.amo.json" -f $database)
[string]$flatfile = (".\output\{0}.rdb.json" -f $database)

$dbInfo = GetDatabaseInfo -database $db

write-host ("::: generating outputs...")
$treejson = $dbInfo | ConvertTo-Json -Depth 20
set-content -Path $treefile -Value $treejson -Force

$flatjson = GetDatabaseFlat -dbinfo $dbInfo | ConvertTo-Json -Depth 20
set-content -Path $flatfile -Value $flatjson -Force

write-host("::: Done.")
