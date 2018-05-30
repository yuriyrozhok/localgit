# ---------------------------------------------------------------------------------------
# Script name:		dimsrc.ps1
# Created:			2018-05-29
# Author:			YRO016
# Description:		Reads the source views/tables/columns for the cube dimensions.
# ---------------------------------------------------------------------------------------
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null;

[string]$srv_name = "SCRBMSBDK000660"
[string]$db_name = "FBR_FYPnL_DPRD"
[string]$cube_name = "FYPnL Cube"

$server = New-Object Microsoft.AnalysisServices.Server
write-host ("::: connecting to SSAS instance: {0} ..." -f $srv_name)
$server.connect($srv_name)
$db = $server.Databases.FindByName($db_name)
write-host("::: database: [{0}]" -f $db.Name)
$cube = $db.Cubes.FindByName($cube_name)
write-host("::: state of the cube [{0}]: {1}" -f $cube.Name, $cube.State)
write-host("::: dimensions:")
#foreach ($cubedim in $cube.Dimensions) 
$cubedim = $cube.Dimensions[0]

$dbdim = $cubedim.Dimension
write-host("[{0}] -> [{1}], visible: {2}" -f $cubedim.Name, $dbdim.Name, $(if ($cubedim.Visible) {"Yes"} else {"No"}))
<#
	foreach ($cubeattr in $cubedim.Attributes) {
		$attr = $cubeattr.Attribute
		write-host("[{0}], name col: [{1}]" -f $attr.Name, $attr.NameColumn)
	}
	#>
$attr = $dbdim.Attributes[0]
write-host("[{0}], name col: [{1}]" -f $attr.Name, $attr.NameColumn)

#$tb = $attr.Source
[Microsoft.AnalysisServices.ColumnBinding]$cb = $attr.NameColumn.Source;
write-host("Column ID [{0}], Table ID: [{1}]" -f $cb.ColumnID, $cb.TableID)

[System.Data.DataSet]$schema = $dbdim.DataSourceView.Schema
#[System.Data.DataTable]$dt = $schema.Tables[$cb.TableID]

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

function AnalysisStateToString {
    param (
        [Parameter(Mandatory = $true)] $state
	)	
	switch($state) {
		[Microsoft.AnalysisServices.AnalysisState].Unprocessed {$statestr = "Unprocessed"}
		[Microsoft.AnalysisServices.AnalysisState].Processed {$statestr = "Processed"}
		[Microsoft.AnalysisServices.AnalysisState].PartiallyProcessed {$statestr = "PartiallyProcessed"}
		default {$statestr = "Unknown"}
	}
    return $statestr
}

function GetDatabaseDimensionInfo {
    param (
        [Parameter(Mandatory = $true)] $dbdim
    )	
    $attrs = GetDatabaseDimensionAttributes -dbdim $dbdim
	$keyattr = GetDimensionAttributeInfo -attr $dbdim.KeyAttribute
	$state = AnalysisStateToString -state $dbdim.State
    $dbdimInfo = @{
        ID            = $dbdim.ID
        Name          = $dbdim.Name
        FriendlyName  = $dbdim.FriendlyName
        LastProcessed = '{0:yyyy-MM-dd hh:mm}' -f $dbdim.LastProcessed
        State         = $state
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
        ID            = $cubedim.ID
        Name          = $cubedim.Name
        FriendlyName  = $cubedim.FriendlyName
        Attributes    = $attrs
    }
    return $cubedimInfo
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
#$attrInfo = GetCubeAttributeInfo -attr $cubedim.Attributes[0]
#$dimattr = GetDimensionAttributeInfo -attr $cubedim.Attributes[0].Attribute
#$attrs = GetDimensionAttributes -dbdim $dbdim

#$diminfo = GetDatabaseDimensionInfo -dbdim $dbdim
$diminfo = GetCubeDimensionInfo -cubedim $cubedim

write-host($diminfo | ConvertTo-Json -Depth 10)

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
        #write-host($tabInfo | ConvertTo-Json -Compress)
    }
    return $schemaInfo
}

function GetDsvInfo {
    param (
        [Parameter(Mandatory = $true)] $database
    )		
    $dsvInfo = @()
    foreach ($dsv in $database.DataSourceViews) {
        #$dsv = $db.DataSourceViews[0]
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

$dsvInfo = GetDsvInfo -database $db
#write-host($dsvInfo | ConvertTo-Json)


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

$dsInfo = GetDataSourceInfo -database $db
#write-host($dsInfo | ConvertTo-Json)

#if ($islog -eq $null) {$islog = "N/A"}
#write-host("[IsLogical]=[{0}]" -f $islog)

<#
	if ($tb -is [Microsoft.AnalysisServices.QueryBinding]) {
		write-host("QueryBinding")
	}
	elseif ($tb -is [Microsoft.AnalysisServices.TableBinding]) {
		write-host("TableBinding")
	}
	elseif ($tb -is [Microsoft.AnalysisServices.DsvTableBinding]) {
		write-host("DsvTableBinding")
	}
#>
write-host("::: Done.")
