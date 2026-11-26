using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Admin
{
    public class ActivityLogEntry
    {
        [Key]
        public int intActivityID { get; set; }
        public string strType { get; set; }
        public string strProcess { get; set; }
        public string strDescription { get; set; }
        public DateTime dteAction { get; set; }
        public string strUserName { get; set; }
    }
}
