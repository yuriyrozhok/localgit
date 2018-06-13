using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Security.Principal;
using System.DirectoryServices.AccountManagement;


namespace Maersk.SSAS.Management
{
    class UserEntry
    {
        public string Sid { get; set; }
        public string Uid { get; set; }
        public string DisplayName { get; set; }
        public string EmailAddress { get; set; }
        public string EmployeeId { get; set; }
        public string UserPrincipalName { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string VoiceTelephoneNumber { get; set; }
        public UserEntry(string user_name)
        {
            Uid = user_name;
            //WindowsIdentity wid = new WindowsIdentity("YRO016@crb.apmoller.net");
            UserPrincipal up = UserPrincipal.FindByIdentity(
                UserPrincipal.Current.Context, IdentityType.SamAccountName, Uid);
            Sid = up.Sid.Value;
            DisplayName = up.DisplayName;
            EmailAddress = up.EmailAddress;
            EmployeeId = up.EmployeeId;
            UserPrincipalName = up.UserPrincipalName;
            FirstName = up.GivenName;
            LastName = up.Surname;
            VoiceTelephoneNumber = up.VoiceTelephoneNumber;
        }
    }

    class SecurityInfo
    {
        public static List<UserEntry> getUserEntryList(List<string> users)
        {
            var entries = (from t in users select new UserEntry(t));
            return entries.ToList<UserEntry>();
        }
    }
}
