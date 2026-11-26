using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Dashboard
{
    public class TeamActivityMember
    {
        [Key]
        public int intUserID { get; set; }
        public string strUserName { get; set; }
        public int? intTaskID { get; set; }
        public string? strTaskName { get; set; }
        public string? strProjectName { get; set; }
        public int PendingCount { get; set; }
    }
}
