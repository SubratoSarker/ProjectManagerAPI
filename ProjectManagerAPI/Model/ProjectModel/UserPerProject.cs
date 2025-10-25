using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.ProjectModel
{
    public class UserPerProject
    {
        [Key]
        public int intUserID { get; set; }
        public int intProjectID { get; set; }
        public string strUserName { get; set; }
        public bool isActive { get; set; }
        public bool isKeyPerson { get; set; }
    }
}
