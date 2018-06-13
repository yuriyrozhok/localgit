using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Reflection;
using System.IO;

namespace Maersk.SSAS.Management
{
    class DataExport
    {
        public delegate void PercentDoneCallback(double percent);
        public static void ExportCollectionToTextFile<T>(List<T> list, string filePath, PercentDoneCallback percentDoneCallback = null)
        {
            Type type = list[0].GetType();
            PropertyInfo[] properties = type.GetProperties();
            TextWriter tw = new StreamWriter(filePath, false);
            //adding header row
            StringBuilder sb = new StringBuilder();
            foreach (PropertyInfo property in properties)
            {
                sb.Append(property.Name + "\t");
            }
            tw.WriteLine(sb.ToString().Trim());
            //adding data rows
            double pct = list.Count / 100.0;
            int i = 0, pctDone = 0, pctReported = 0;
            try
            {
                foreach (T t in list)
                {
                    sb = new StringBuilder();
                    foreach (PropertyInfo property in properties)
                    {
                        sb.Append(property.GetValue(t, null) + "\t");
                    }
                    tw.WriteLine(sb.ToString().Trim());
                    if (percentDoneCallback != null) {
                        pctDone = (int)Math.Round(++i / pct, 0);
                        if (pctDone % 10 == 0 & pctDone != pctReported)
                        {
                            percentDoneCallback(pctDone/100.0);
                            pctReported = pctDone;
                        }
                    }
                }
            }
            finally
            {
                tw.Close();
            }

        }
    }
}
