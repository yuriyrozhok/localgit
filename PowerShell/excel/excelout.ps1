function CreateExcelWorkbook {
<#
Excel.Application: https://msdn.microsoft.com/en-us/library/microsoft.office.interop.excel.application_members.aspx
Excel.Workbook: https://msdn.microsoft.com/en-us/library/microsoft.office.interop.excel.workbook_members.aspx
Excel.PivotCache: https://msdn.microsoft.com/en-us/library/microsoft.office.interop.excel.pivotcache_members.aspx
Excel.PivotTable: https://msdn.microsoft.com/en-us/library/microsoft.office.interop.excel.pivottable_members.aspx

Excel.XlPivotTableSourceType.xlExternal == 2

Excel.XlPivotFieldOrientation.xlRowField == 1
Excel.XlPivotFieldOrientation.xlColumnField == 2
Excel.XlPivotFieldOrientation.xlPageField == 3
Excel.XlPivotFieldOrientation.xlDataField == 4
#>
	#$stype = new-object Excel.XlPivotTableSourceType
	try {
		$excel = new-object -comobject Excel.Application
		#$excel.Visible = $true
		$wbook = $excel.Workbooks.Add()
		$sheet = $wbook.Worksheets.Item(1)
		#$sheet.Cells.Item(1,1) = "Added by PowerShell"
		
		$cstr = "OLEDB;Provider=MSOLAP.5;Integrated Security=SSPI;Persist Security Info=True;Data Source=ADL2;Update Isolation Level=2;Initial Catalog="
		$src = @($cstr, "CYF")
		$cn = $wbook.Connections.Add2("CYF", "", $src, "CYF", 1)
		$pc = $wbook.PivotCaches().Create(2, $cn); #xlExternal == 2
		
		$ptab = $pc.CreatePivotTable($excel.ActiveCell, "PivotTable1")
		$pf = $ptab.AddDataField($ptab.CubeFields("[Measures].[FFE]"))
		
		#$obj = $ptab.AddFields($ptab.CubeFields("[Brand].[Brand]"))
		$cubf = $ptab.CubeFields("[Brand].[Brand]")
		$cubf.Orientation = 1 #xlRowField == 1
		$cubf.Position = 1
		
		$wbook.SaveAs("C:\yrozhok\_Generic\datatest\Test.xlsx")
		$wbook.Close();       
		$excel.Quit();
		
	}
	finally {
		<#
			all COM objects must be released, otherwise Excel doesn't quit and process will run in background
			see these articles:
			https://technet.microsoft.com/en-us/library/ff730962.aspx
			https://social.technet.microsoft.com/Forums/lync/en-US/81dcbbd7-f6cc-47ec-8537-db23e5ae5e2f/excel-releasecomobject-doesnt-work?forum=ITCG
		#>
		$comObjs = @($cubf, $pf, $ptab, $pc, $cn, $sheet, $wbook, $excel)
		foreach ($com in $comObjs) {
			while( [System.Runtime.Interopservices.Marshal]::ReleaseComObject($com)){}
		}
		#[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
		Remove-Variable excel
		[System.GC]::Collect()
	}
}
CreateExcelWorkbook;