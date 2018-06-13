using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AnalysisServices;

namespace Maersk.SSAS.Management
{
    class CubeInfo
    {
        private Microsoft.AnalysisServices.Server Server;
        private Microsoft.AnalysisServices.Database Database;
        private Microsoft.AnalysisServices.Cube Cube;
        private Microsoft.AnalysisServices.MeasureGroup MeasureGroup;
        private Microsoft.AnalysisServices.Partition Partition;

        private string serverName;
        private string dbName;
        public CubeInfo(string server_name, string db_name)
        {
            Server = new Microsoft.AnalysisServices.Server();
            serverName = server_name;
            dbName = db_name;
        }
        public void Connect()
        {
            Server.Connect(serverName);
            Database = Server.Databases.FindByName(dbName);
            //Database.Cubes[0].MeasureGroups[0].AggregationDesigns[0].Aggregations[0].Dimensions[0].Attributes
        }
        public List<string> getUsers(string role_name)
        {
            Microsoft.AnalysisServices.Role role = Database.Roles.FindByName(role_name);
            var users = (from t in role.Members.Cast<RoleMember>() select t.Name); //.Take(5);
            return users.ToList<string>();
        }
        public void getCommands(string cube_name)
        {
            Cube = Database.Cubes.FindByName(cube_name);
            foreach (Microsoft.AnalysisServices.MdxScript mdx in Cube.MdxScripts)
            {
                foreach (Microsoft.AnalysisServices.Command cmd in mdx.Commands)
                {
                    Console.WriteLine("* * * * * * * * *");
                    Console.WriteLine(cmd.Text);
                }
            }
        }
        //<KCALC.XPR>
        public Microsoft.AnalysisServices.Command findCommandByPattern(string cube_name, string pattern)
        {
            Cube = Database.Cubes.FindByName(cube_name);
            //Microsoft.AnalysisServices.Command cmd;
            foreach (Microsoft.AnalysisServices.MdxScript mdx in Cube.MdxScripts)
            {
                foreach (Microsoft.AnalysisServices.Command cmd in mdx.Commands)
                {
                    if (cmd.Text.Contains(pattern))
                    {
                        return cmd;
                    }
                }
            }
            return null;
        }
        public void replaceMdxBlock(string tag, string mdx_new)
        {
            Cube = Database.Cubes.FindByName("KPI");
            Command cmd;
            //Command cmd = findCommandByPattern("KPI", "<KCALC.XPR>");
            MdxScript script = Cube.MdxScripts[0];
            
            cmd = script.Commands[0];

            string mdx = cmd.Text;
            string tag_start = String.Format("//<{0}>", tag);
            string tag_end = String.Format("//</{0}>", tag);
            int kpi_from = mdx.IndexOf(tag_start) + tag_start.Length;
            int kpi_to = mdx.IndexOf(tag_end) - 1;
            
            mdx = mdx.Remove(kpi_from, kpi_to - kpi_from + 1);
            mdx = mdx.Insert(kpi_from, mdx_new);
            cmd.Text = mdx;


            /*
                        script.Commands.Remove(cmd); //  At(i);
                        //script.Update();
                        cmd = new Command();
                        cmd.Text = mdx;
                        script.Commands.Add(cmd);
              */
            script.Update();
            Cube.Update();
            //Cube.Update(UpdateOptions.ExpandFull);

        }
        public void Disconnect()
        {
            if (Server != null & Server.Connected == true)
            {
                Server.Disconnect();
            }
        }
        ~CubeInfo()
        {
            Disconnect();
        }

    }
}
