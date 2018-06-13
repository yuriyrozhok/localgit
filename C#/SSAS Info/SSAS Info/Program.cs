using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AnalysisServices;
using System.Data;

namespace Maersk.SSAS.Management
{
	class Program
	{
		private static void logMessage(string msg)
		{
			Console.WriteLine(msg);
		}
		private static void logMessageFmt(string msg, params object[] parameters)
		{
			Console.WriteLine(String.Format(msg, parameters));
		}
		static void PartitionInfo()
		{
            string srv_name = @"SCRBMSBDK000660";
            string db_name = "FBR_FYPnL_DPRD";
            string cube_name = "FYPnL Cube";
            string mg_name = "USD";
            //TextWriter tw = new StreamWriter("date.txt", true);

            Microsoft.AnalysisServices.Server srv;
			Microsoft.AnalysisServices.Database db;

			srv = new Microsoft.AnalysisServices.Server();
			try
			{
				srv.Connect(srv_name);
				logMessageFmt("Databases on [{0}]: {1}", srv_name, srv.Databases.Count);

				db = srv.Databases.FindByName(db_name);
                
				Cube cube = db.Cubes.FindByName(cube_name);

                CubeDimension cubedim = cube.Dimensions[0];
                Dimension dbdim = cubedim.Dimension;
                DimensionAttribute dbattr = dbdim.Attributes[0];

                //var Source = dbattr.Source;
                System.Data.DataSet ds = dbdim.DataSourceView.Schema;
                string dsid = db.DataSourceViews[0].DataSourceID;
                DataTable dt = db.DataSourceViews[0].Schema.Tables[0];
                //db.DataSources[0].
                //DataTable dt = ds.Tables["SHARED_DimBrand"];
                //ep = dt.ExtendedProperties.

                MeasureGroup mg = cube.MeasureGroups.FindByName(mg_name);
                MeasureGroupDimension mgd = mg.Dimensions[0];
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
                Type t = alist[0].KeyColumns[0].Source.GetType();

                Measure msr = mg.Measures[0];

				foreach (Partition part in mg.Partitions)
				{
                    string src;
                    TabularBinding tb = part.Source;
                    if (tb is QueryBinding)
                    {
                        src = String.Format("QUERY: {0}", ((QueryBinding) tb).QueryDefinition);
                    } else if (tb is TableBinding)
                    {
                        src = String.Format("TABLE: {0}.{1}", ((TableBinding) tb).DbSchemaName, ((TableBinding) tb).DbTableName);
                    } else if (tb is DsvTableBinding)
                    {
                        src = String.Format("DSV: {0}.{1}", ((DsvTableBinding) tb).DataSourceViewID, ((DsvTableBinding) tb).TableID);
                    } else
                    {
                        src = String.Empty;
                    }

                    logMessageFmt("Partition [{0}]: {1}", part.Name, src/*part.EstimatedRows*/);
                    //part.Process()
				}
				//Partition part = mg.Partitions[0]; //.FindByName(part_name);

				logMessage("Done.");
				Console.ReadKey();
			}
			finally
			{
				if (srv.Connected == true)
				{
					srv.Disconnect();
				}
			}

		}

		static void ProcessDimensions()
		{
			string srv_name = @"SCRBSQLDEFRM637";
			string db_name = "Intermodal_TEST";
			//TextWriter tw = new StreamWriter("date.txt", true);

			Microsoft.AnalysisServices.Server srv;
			Microsoft.AnalysisServices.Database db;

			srv = new Microsoft.AnalysisServices.Server();
			try
			{
				srv.Connect(srv_name);
				logMessageFmt("Databases on [{0}]: {1}", srv_name, srv.Databases.Count);

				db = srv.Databases.FindByName(db_name);
				foreach (Dimension d in db.Dimensions)
				{
					logMessageFmt("Processing {0}(ID=[{1}])...", d.Name, d.ID);
					try
					{
						if (d.State != AnalysisState.Processed)
						{
							d.Process(ProcessType.ProcessFull);
							logMessage("---> Processed successfully.");
						}
						else
						{
							logMessage("---> Already processed.");
						}
					}
					catch (Exception e)
					{
						logMessageFmt("---> ERROR: {0}", e.Message);
					}
				}
				logMessage("Done.");
				Console.ReadKey();
			}
			finally
			{
				if (srv.Connected == true)
				{
					srv.Disconnect();
				}
			}

		}
		static string CreatePartition(MeasureGroup mg, string part_key, string query, string slice, DataSource ds, int part_size)
		{
			string part_name = String.Format("{0}_{1}", mg.Name, part_key);
			Partition part = mg.Partitions.FindByName(part_name);
			if (part != null)
				part.Drop();
			part = mg.Partitions.Add(part_name);
			part.StorageMode = StorageMode.Molap;

			part.Source = new QueryBinding(ds.ID, String.Format(query, part_key));
			part.Slice = String.Format(slice, part_key);
			part.EstimatedRows = part_size;
			//part.Annotations.Add("AccountMonthKey", part_key);
			part.Update();
			return part_name;
		}
		static void DropMeasureGroupPartitions(MeasureGroup mg)
		{
			//mg.Partitions.Clear();
			while (mg.Partitions.Count > 0)
			{
				mg.Partitions[0].Drop();
			}
			mg.Update();
		}

			static void CreateMeasureGroupPartitions(MeasureGroup mg, string query, string slice, DataSource ds, int year, int month_from, int month_to
			, int part_size)
		{
			//mg.Partitions.Clear();
			/*
			while (mg.Partitions.Count > 0)
			{
				mg.Partitions[0].Drop();
			}
			*/
			string pkey, pname;
			for (int i = month_from; i <= month_to; i++)
			{
				pkey = String.Format("{0}{1:00}", year, i);
				pname = CreatePartition(mg, pkey, query, slice, ds, part_size);
				logMessageFmt("[{0}]: added partition [{1}].", mg.Name, pname);
			}
			mg.Update();
		}
		static void CreateAllPartitions()
		{
			//https://msdn.microsoft.com/en-us/library/ms345091.aspx

			string srv_name = 
				@"SCRBMSBDK000660\PREPRODQUERYSRV1"; 
				//@"SCRBSQLDEFRM637"; //this one is not enough for Intermodal, always fails during the processing
			string db_name = "Intermodal"; 
				//"Intermodal_TEST";
			string cube_name = "Intermodal Cube";
			//TextWriter tw = new StreamWriter("date.txt", true);

			Microsoft.AnalysisServices.Server srv;
			Microsoft.AnalysisServices.Database db;
			Microsoft.AnalysisServices.Cube cube;
			Microsoft.AnalysisServices.MeasureGroup mg;
			Microsoft.AnalysisServices.Partition part;
			srv = new Microsoft.AnalysisServices.Server();
			try
			{
				srv.Connect(srv_name);
				logMessageFmt("Connected to {0}", srv_name);
				db = srv.Databases.FindByName(db_name);
				cube = db.Cubes.FindByName(cube_name);
				string query, slice;

				
				//-------- USD - Equipment Level
				mg = cube.MeasureGroups.FindByName("USD - Equipment Level");
				/*
					select top 100 percent * from 
					(
					) x
					order by Shipment_CODE_SSL, Equipment_Key

				*/
				query = @"
						select * from DTST12_SIT_DEV.IM_PnLFACTUSDAggrShpCnt
							where AccountMonth_CODE_SSL in (
								select Month_Key from DTST13_APPL_MSBIPNL.PnL_DimPeriodAccountingMonth
								where MonthYYYYMM_No = {0}
						)
				";
				slice = "[Time Accounting period].[Unique Month].&[{0}]";
				logMessageFmt("Database: [{0}], cube: [{1}], measure group: [{2}].", db_name, cube_name, mg.Name);
				DropMeasureGroupPartitions(mg);
				CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2016, 1, 12, 120000000);
				CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2017, 1, 2, 120000000);

				//-------- FFE
				/*
					select top 100 percent * from 
					(
					) x
					order by Shipment_CODE_SSL, Equipment_CODE_SSL

				*/
				mg = cube.MeasureGroups.FindByName("FFE");
				query = @"
						select * from DTST12_SIT_DEV.IM_PnL_FACT_FFEDisc_D
						where AccountMonth_CODE_SSL in (
							select Month_Key from DTST13_APPL_MSBIPNL.PnL_DimPeriodAccountingMonth
							where MonthYYYYMM_No = {0}
						)
						union all
						select * from DTST12_SIT_DEV.IM_PnL_FACT_FFEDisc_L
						where AccountMonth_CODE_SSL in (
							select Month_Key from DTST13_APPL_MSBIPNL.PnL_DimPeriodAccountingMonth
							where MonthYYYYMM_No = {0}
						)
				";
				slice = "[Time Accounting period].[Unique Month].&[{0}]";
				logMessageFmt("Database: [{0}], cube: [{1}], measure group: [{2}].", db_name, cube_name, mg.Name);
				DropMeasureGroupPartitions(mg);
				CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2016, 1, 12, 2000000);
				CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2017, 1, 2, 2000000);

				//-------- Equipment Moves
				/*
					select top 100 percent * from 
					(
					) x
					order by Shipment_Key

				*/
				mg = cube.MeasureGroups.FindByName("Equipment Moves");
				query = @"
						select * from DTST12_SIT_DEV.IM_tF_PnLContMovAggr
							where AccountingMonth_Key in (
								select Month_Key from DTST13_APPL_MSBIPNL.PnL_DimPeriodAccountingMonth
								where MonthYYYYMM_No = {0}
						)
				";
				slice = "[Time Accounting period].[Unique Month].&[{0}]";
				logMessageFmt("Database: [{0}], cube: [{1}], measure group: [{2}].", db_name, cube_name, mg.Name);
				DropMeasureGroupPartitions(mg);
				CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2016, 1, 12, 10000000);
				CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2017, 1, 2, 10000000);

				//-------- USD - Shipment Level
				/*
				select top 100 percent* from
					(
					) x
					order by Shipment_CODE_SSL

					*/
				mg = cube.MeasureGroups.FindByName("USD - Shipment Level");
				query = @"
						select * from DTST12_SIT_DEV.IM_tF_PnLFACTUSDAggr_Limited
							where AccountMonth_CODE_SSL in (
								select Month_Key from DTST13_APPL_MSBIPNL.PnL_DimPeriodAccountingMonth
								where MonthYYYYMM_No = {0}
						)
				";
				slice = "[Time Accounting period].[Unique Month].&[{0}]";
				logMessageFmt("Database: [{0}], cube: [{1}], measure group: [{2}].", db_name, cube_name, mg.Name);
				DropMeasureGroupPartitions(mg);
				CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2016, 1, 12, 250000);
				CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2017, 1, 2, 250000);
				
				cube.Update();
				
			}
			finally
			{
				if (srv.Connected == true)
				{
					srv.Disconnect();
				}
			}

		}
		private static void ExportCubeRoleUsers(string role_name)
		{
			//CubeInfo cubeInfo = new CubeInfo("ADL1", "ADL_YIP");
			CubeInfo cubeInfo = new CubeInfo("SCRBADLDK003869", "OOS");
			try
			{
				cubeInfo.Connect();
				List<string> users = cubeInfo.getUsers(role_name);
				List<UserEntry> ue = SecurityInfo.getUserEntryList(users);
				DataExport.ExportCollectionToTextFile(ue, String.Format(@"C:\yrozhok\EMR\Security\{0}.txt", role_name),
					delegate(double pct) { Console.WriteLine("{0:P2}", pct); });

			}
			finally
			{
				cubeInfo.Disconnect();
			}
		}
		private static void UpdateMdxScript()
		{
			CubeInfo cubeInfo = new CubeInfo("SCRBSQLDEFRM637", "BICC_PerformanceManagement_DEV");
			try
			{
				cubeInfo.Connect();
				//cubeInfo.getCommands("KPI");
				cubeInfo.replaceMdxBlock("KCALC.XPR", @"[Key Figure].[Key Figure Code].&[K.MLB.020] = [Key Figure].[Key Figure Code].&[K.MLB.019]
	* [Key Figure].[Key Figure Code].&[K.MLB.020];");
			}
			finally
			{
				cubeInfo.Disconnect();
			}
		}
        private static void ReadPartitionInfo()
        {
                string srv_name = @"SCRBMSBDK000660";
                string db_name = "BICC_Intermodal";
                string cube_name = "Intermodal Cube";
                //TextWriter tw = new StreamWriter("date.txt", true);

                Microsoft.AnalysisServices.Server srv;
                Microsoft.AnalysisServices.Database db;
                Microsoft.AnalysisServices.Cube cube;
                Microsoft.AnalysisServices.MeasureGroup mg;
                Microsoft.AnalysisServices.Partition part;
                srv = new Microsoft.AnalysisServices.Server();
                try
                {
                    srv.Connect(srv_name);
                    logMessageFmt("Connected to {0}", srv_name);
                    db = srv.Databases.FindByName(db_name);
                    cube = db.Cubes.FindByName(cube_name);
                    string query, slice;

                    mg = cube.MeasureGroups.FindByName("USD - Equipment Level");

                    logMessageFmt("Database: [{0}], cube: [{1}], measure group: [{2}].", db_name, cube_name, mg.Name);
                    //DropMeasureGroupPartitions(mg);
                    //CreateMeasureGroupPartitions(mg, query, slice, db.DataSources[0], 2016, 1, 12, 120000000);
            }
            finally
            {
                if (srv.Connected == true)
                {
                    srv.Disconnect();
                }
            }

        }
    

        static void Main(string[] args)
		{

			PartitionInfo();

			//CreateAllPartitions();


			//ExportCubeRoleUsers("Business");

			/*
			ExportCubeRoleUsers("SEAGO Reader");
			ExportCubeRoleUsers("SEALAND Reader");
			ExportCubeRoleUsers("MCC Reader");
			ExportCubeRoleUsers("LOC POD - LAM");
			ExportCubeRoleUsers("LOC POR - LAM");
			*/

			//UpdateMdxScript();

			logMessage("---------- Done.");
			Console.ReadKey();
		}
	}
}
