using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class Teammate
    {
        [Key]
        public int intUserID { get; set; }
        public string strUserName { get; set; }
    }
}
