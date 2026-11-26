using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Admin
{
    public class OffboardingUser
    {
        [Key]
        public int intUserID { get; set; }
        public string strUserName { get; set; }
        public bool isActive { get; set; }
        public string strTeamName { get; set; }
    }
}
