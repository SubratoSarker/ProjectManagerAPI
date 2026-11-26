using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Dashboard
{
    public class WorkloadItem
    {
        [Key]
        public int intUserID { get; set; }
        public string strUserName { get; set; }
        public int OpenTaskCount { get; set; }
    }
}
