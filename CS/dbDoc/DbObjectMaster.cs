using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace dbDoc
{
    class DbObjectMaster
    {
        private string defaultDatabase;
        public string DefaultDatabase {
            get { return defaultDatabase; }
            set
            {
                defaultDatabase = value.Trim().ToUpper();
            }
        }
        public Dictionary<string, DbObject> DbObjectBus;

        public DbObjectMaster() {
            DbObjectBus = new Dictionary<string, DbObject>(StringComparer.OrdinalIgnoreCase);
        }
        public void Add(DbObject obj)
        {
            if (!DbObjectBus.ContainsKey(obj.FullName)) {
                DbObjectBus.Add(obj.FullName, obj);
            } /*else
            {
                DbObject curr_obj = DbObjectBus[obj.FullName];
                curr_obj.Type = obj.Type;
            }*/
        }
        public DbObject AddNew(string name, string type, 
            string database = null, string text = null)
        {
            DbObject obj = new DbObject(name, type, this, database, text);
            Add(obj);
            return obj;
        }
        public void BuildReferences()
        {
            DbObject src_obj;
            IEnumerable<string> names = DbObjectBus.Keys.ToList();
            IEnumerable<string> src_names;
            foreach (string curr_name in DbObjectBus.Keys)
            {
                src_names = DbObjectBus[curr_name].Sources.Keys.ToList();
                foreach (string src_name in src_names)
                {
                    if (DbObjectBus.TryGetValue(src_name, out src_obj))
                    {
                        src_obj.Targets.Add(curr_name, DbObjectBus[curr_name]);
                        DbObjectBus[curr_name].Sources[src_name] = src_obj;
                    }
                }
            }
        }
        private DbObjectTree getChildSubTree(DbObject child, DbObjectTree parent)
        {
            DbObjectTree tree = new DbObjectTree(child, parent);
            //this checks for circular references otherwise the tree will never end
            if (!parent.ParentExists(child.Name))
            {
                foreach (string src_name in DbObjectBus[child.FullName].Sources.Keys)
                {
                    tree.children.Add(getChildSubTree(DbObjectBus[src_name], tree));
                }
            }
            return tree;
        }
        public DbObjectTree getDbObjectTreeFlowEnd()
        //list of the objects rooted by the objects which have no targets (the last ones in the data flow chain)
        {
            DbObjectTree dot = new DbObjectTree("(dfe)", "R", null, null); //root level - no parent
            List<DbObjectTree> tree = DbObjectBus.Values
                .Where(d => d.Targets.Count == 0)
                .Select(d => getChildSubTree(d, dot))
                .ToList();
            dot.children = tree;
            return dot;
        }
        public DbObjectTree getDbObjectTree()
        //list of the all objects
        {
            DbObjectTree dot = new DbObjectTree("(all)", "R", null, null); //root level - no parent
            List<DbObjectTree> tree = DbObjectBus.Values
                //must be some filter here like: .Where(d => d.Sources.Count == 0)
                .Select(d => getChildSubTree(d, dot))
                .ToList();
            dot.children = tree;
            return dot;
        }

    }
}
