using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Admin
{
    public class AllUser
    {
        [Key]
        public int intUserID { get; set; }
        public string strUserName { get; set; }
        public string strPhone { get; set; }
        public string strEmail { get; set; }
        public int intTeamID { get; set; }
        public string strTeamName { get; set; }
        public int intBoss { get; set; }
        public bool isLocked { get; set; }
    }
}
