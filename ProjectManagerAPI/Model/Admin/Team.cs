using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Admin
{
    public class Team
    {
        [Key]
        public int intTeamID { get; set; }
        public string strTeamName { get; set; }
    }
}
