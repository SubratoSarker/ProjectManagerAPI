using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Admin
{
    public class CompleatedReport
    {
        [Key]
        public int intTaskID { get; set; }
        public string strTaskName { get; set; }
        public string strDescription { get; set; }
        public string strRequestFrom { get; set; }
        public string strProjectName { get; set; }
        public string strUserName { get; set; }
        public string strTeamName { get; set; }
        public string strStatus { get; set; }
    }
}
