using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using Teradata.Client.Provider;
//using System.Web.Http;
using Newtonsoft.Json;
using System.IO;

namespace dbDoc
{
    class Program
    {
        static void readSqlServer()
        {
            string queryString = @"SELECT  
    m.definition
FROM sys.views v
INNER JOIN sys.sql_modules m ON m.object_id = v.object_id
WHERE name = @viewname
                ";
            string connectionString = @"Server=.\SQL14MD;Database=NORTHWND;Integrated Security=true";
            string str;
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                SqlCommand cmd = new SqlCommand(queryString, connection);
                cmd.Parameters.AddWithValue("@viewname", "Invoices");
                connection.Open();

                //cmd.CommandText = "SELECT treatment FROM appointment WHERE patientid = " + text;
                cmd.CommandText = queryString;
                str = Convert.ToString(cmd.ExecuteScalar());
                connection.Close();
            }

            Console.WriteLine(str);
            //str = compressQueryText(str);
            Console.WriteLine(str);
            //getObjectsFromQuery(str, "NORTHWND");
            Console.WriteLine("*******************************************");
        }
        static void readTeradata()
        {
            string db_name = @"DPRD_SSL_MDM_V"; // @"LabBICC_Test";LabBICC_FIN_DYI
            string queryTemplate = @"
SELECT TableName, tablekind, case tablekind when 'V' then RequestText else null end as RequestText
FROM dbc.tablesv 
WHERE tablekind in ('V', 'T') AND databasename IN ('{0}') 
AND TableName = 'vD_GeoSite'
--AND TableName LIKE 'vD_Equipment_%'
            ";
            //and (TableName like 'MSBI_vF_Fixed%' or TableName like 'MSBI_vD_Report%')
            // AND TableName like 'MSBI_%'
            //in ('MSBI_vD_KeyFigureGroup', 'vD_KeyFigureGroup', 'vD_KeyFigureGroupCateg')
            DbObjectMaster objMaster = new DbObjectMaster();
            objMaster.DefaultDatabase = db_name;

            string queryString = String.Format(queryTemplate, db_name);
            TdConnection cn = new TdConnection();
            string connectionString = @"Data Source=maersk6;Database=LabBICC_Test;User Id=UADL_BICC_LOADUSER;Password=Lab@BICC123;Connection Timeout=300;";
            string obj_text = "", obj_name = "", obj_type = "";
            using (TdConnection connection = new TdConnection(connectionString))
            {
                //connection.ConnectionTimeout = 300; //covered by connection string
                TdCommand cmd = new TdCommand(queryString, connection);
                cmd.CommandTimeout = 180;
                //cmd.Parameters.Add(new TdParameter("@viewname", "MSBI_vD_Company"));
                //cmd.CommandText = queryString;
                Console.WriteLine("Acquiring the connection....");
                connection.Open();
                Console.WriteLine("Getting database object list....");
                TdDataReader reader = cmd.ExecuteReader();
                //Console.WriteLine("{0} tables found.", reader.RecordsAffected);
                while (reader.Read())
                {
                    obj_name = reader["TableName"].ToString().Trim();
                    obj_type = reader["tablekind"].ToString().Trim().ToUpper();
                    obj_text = reader["RequestText"].ToString().Trim();
                    //str = Convert.ToString(cmd.ExecuteScalar());
                    //str = (string)cmd.ExecuteScalar();

                    //obj_text = compressQueryText(obj_text);
                    //str = "[" + str + "]";
                    obj_name = obj_name.IndexOf(".") >= 0 ? obj_name : db_name + "." + obj_name;
                    //DbObject obj = new DbObject(obj_name, obj_type, objMaster, db_name, obj_text);
                    DbObject obj = objMaster.AddNew(obj_name, obj_type, db_name, obj_text);
                    Console.WriteLine(obj_name);
                    //Console.WriteLine(obj_text);
                    Console.WriteLine("::: source objects :::");
                    foreach (DbObject src in obj.Sources.Values)
                    {
                        Console.WriteLine(src.Name);
                    }
                    Console.WriteLine("*******************************************");
                    //objMaster.Add(obj);
                }
                cmd.Dispose();
                connection.Close();
            }
            objMaster.BuildReferences();

            //var json = ApiResponse 

            //var json = JsonConvert.SerializeObject(objMaster);

            //this gets all objects and user drills down to their sources (if any)
            //this way some objects may appear in different branches of the tree
            DbObjectTree tree = objMaster.getDbObjectTree();

            //this starts from the objects that have no targets (no one is sourced from them)
            //and user drills down to the sources, nvigating to the other objects this way
            //DbObjectTree tree = objMaster.getDbObjectTreeFlowEnd();

            tree.GroupChildrenBySchema();
            tree.SortTree();
            tree.AddIcons();
            //tree.CleanParents();
            var json = JsonConvert.SerializeObject(tree);
            //Console.WriteLine(json);
            File.WriteAllText(@"C:\TEMP\views.json", json);
            //File.WriteAllText(@"\\SCRBADLDK003868\db\views.json", json);

        }
        static void Main(string[] args)
        {
            readTeradata();
            Console.WriteLine("Done. Press any key...");
            Console.ReadKey();
        }
    }
}
