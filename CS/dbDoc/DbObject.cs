using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace dbDoc
{
    class DbObject
    {
        protected DbObjectMaster objMaster;
        private string objName;
        public string Name {
            get { return objName; }
            set {
                string name = value.Trim();
                string[] s = name.Split('.');
                if (s.Length == 1)
                {
                    objName = s[0];
                }
                else
                {
                    this.Database = s[0].ToUpper();
                    objName = s[1];
                }
            }
        }
        public string FullName
        {
            get { return String.Format("{0}.{1}", Database, Name); }
        }
        public string Type { get; set; }
        public string Database { get; set; }

        private string originalQueryText;
        private string compressedQueryText;
        public string QueryText
        {
            get { return originalQueryText; }
            set {
                originalQueryText = value;
                if (value != null)
                {
                    compressedQueryText = compressQueryText(value);
                    RefreshSourceObjects();
                }
            }
        }

        public Dictionary<string, DbObject> Sources;
        public Dictionary<string, DbObject> Targets;

        public DbObject(string name, string type, DbObjectMaster master, string database = null,
                string text = null) {
            objMaster = master;
            this.Database = database == null ? master.DefaultDatabase : database.Trim().ToUpper();
            this.Type = type.Trim().ToUpper();
            this.Name = name;
            Sources = new Dictionary<string, DbObject>(StringComparer.OrdinalIgnoreCase);
            Targets = new Dictionary<string, DbObject>(StringComparer.OrdinalIgnoreCase);
            this.QueryText = text;
        }
        private string compressQueryText(string query)
        {
            //remove all comments (they can contains key words)
            string s = "  " + query + "  \r";
            int p1, p2;
            while (s.IndexOf("/*") >= 0)
            {
                p1 = s.IndexOf("/*");
                p2 = s.IndexOf("*/", p1 + 2) + 1;
                s = s.Remove(p1, p2 - p1 + 1);
            }
            while (s.IndexOf("--") >= 0)
            {
                p1 = s.IndexOf("--");
                p2 = s.IndexOf("\r", p1 + 2);
                s = s.Remove(p1, p2 - p1 + 1);
            }
            //remove all string literals (they can contains key words)
            while (s.IndexOf("''") >= 0)
            {
                s = s.Replace("''", "");
            }
            while (s.IndexOf("'") >= 0)
            {
                p1 = s.IndexOf("'");
                p2 = s.IndexOf("'", p1 + 1);
                s = s.Remove(p1, p2 - p1 + 1);
            }
            //compress non-printable symbols and spaces
            s = s.Replace("\n", " ").Replace("\r", " ").Replace("\t", " ")
                .Replace("(", " ").Replace(")", " ");
            //replace multiple spaces with single spaces
            while (s.IndexOf("  ") >= 0)
            {
                s = s.Replace("  ", " ");
            }
            return s;
        }

        private IEnumerable<string> ExtractNamesFromQueryText()
        {
            HashSet<string> sources = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            int p1, p2;
            string objname, s;
            string query = compressedQueryText.Replace(";", " ") + " ";
            string str = query.ToUpper().Replace(" JOIN ", " FROM ");
            int idx = str.IndexOf(" FROM ");
            //iterate through all occurences of "FROM"
            while (idx >= 0)
            {
                p1 = idx + 6; //length of " FROM " keyword
                s = str.Substring(p1, 1);
                if (s == "\"") //some objectnames can be wrapped with double quotes
                {
                    p2 = str.IndexOf("\"", p1 + 1);
                }
                else
                {
                    p2 = str.IndexOf(" ", p1);
                }
                objname = /*str*/query.Substring(p1, p2 - p1 + 1).Trim().ToUpper();
                if (objname != "SELECT" && objname != "SEL")
                {
                    objname = objname.Trim();
                    objname = objname.IndexOf(".") >= 0 ? objname : Database + "." + objname;
                    sources.Add(objname);
                }
                idx = str.IndexOf(" FROM ", p2);
            }
            return sources;
        }
        private void RefreshSourceObjects()
        {
            IEnumerable<string> names = ExtractNamesFromQueryText();
            Sources.Clear();
            foreach(string s in names)
            {
                //every source object must be added to the master bus
                DbObject obj = objMaster.AddNew(s, "?", Database 
                    /* object type and text are unknown at this stage*/);
                Sources.Add(s, obj);
                //Sources.Add(s, new DbObject(s, "?", objMaster));
            }            
        }


    }
}
