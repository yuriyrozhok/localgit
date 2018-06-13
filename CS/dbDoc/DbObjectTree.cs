using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace dbDoc
{
    class DbObjectTree
    {
        private string fullname;
        public string name;
        protected string objtype;
        protected string database;
        /*
        public string name  {
            get { return this.fullname; }
            set
            {
                this.fullname = value.Trim();
                string[] s = fullname.Split('.');
                this.schema = s[0].ToUpper();
                this.objtype = s[1].ToUpper();
                this.objname = s[2];
            }
        }
        */
        protected DbObjectTree parent { get; set; }
        public List<DbObjectTree> children { get; set; }

        public DbObjectTree(DbObject obj, DbObjectTree parent)
        {
            this.name = obj.Name;
            this.objtype = obj.Type;
            this.database = obj.Database;
            this.parent = parent;
            this.children = new List<DbObjectTree>();
        }
        public DbObjectTree(string name, string type, DbObjectTree parent, List<DbObjectTree> children)
        {
            this.name = name;
            this.objtype = type;
            this.parent = parent;
            this.children = children;
        }
        public bool ParentExists(string name)
        {
            return parent == null ? false : this.name == name || parent.ParentExists(name);
        }
        //temporarily, just for JSON serializer to avoid circular references
        //TODO: better solution to be designed
        public void CleanParents()
        {
            parent = null;
            foreach (DbObjectTree child in children)
            {
                child.CleanParents();
            }
        }
        public void SortTree()
        {
            foreach (DbObjectTree child in children)
            {
                child.SortTree();
            }
            children.Sort((x, y) => x.name.CompareTo(y.name));
        }
        public void GroupChildrenBySchema()
        {
            DbObjectTree cschema;
            int idx;
            List<DbObjectTree> schemas = new List<DbObjectTree>();
            foreach (DbObjectTree child in children)
            {
                child.GroupChildrenBySchema();
                idx = schemas.FindIndex(x => x.name.ToUpper() == child.database.ToUpper());
                if (idx < 0)
                {
                    cschema = new DbObjectTree(child.database, "D", this, new List<DbObjectTree>());
                    schemas.Add(cschema);
                }
                else
                {
                    cschema = schemas[idx];
                }
                cschema.children.Add(child);
            }
            this.children = schemas;
            /*
            var groupedCustomerList = children
                .GroupBy(u => u.schema)
                .Select(grp => grp.ToList())
                .ToList();
                */
        }
        public void GroupChildrenByType()
        {

        }
        public void AddIcons()
        {
            string fa = @"<i class='fa fa-{0}' style='font-size:16px;color:{1};'>&nbsp;{2}</i>";
            foreach (DbObjectTree child in children)
            {
                child.AddIcons();
                switch (child.objtype)
                {
                    case "R":
                        child.name = String.Format(fa, "sitemap", "black", child.name);
                        break;
                    case "D":
                        child.name = String.Format(fa, "database", "black", child.name);
                        break;
                    case "T":
                        child.name = String.Format(fa, "table", "DodgerBlue", child.name);
                        break;
                    case "V":
                        child.name = String.Format(fa, "th-list", "Crimson", child.name);
                        break;
                    case "M":
                        child.name = String.Format(fa, "arrow-alt-circle-right", "LimeGreen", child.name);
                        break;
                    default:
                        child.name = String.Format(fa, "question-circle", "SlateGray", child.name);
                        break;
                }

            }
        }
    }
}
