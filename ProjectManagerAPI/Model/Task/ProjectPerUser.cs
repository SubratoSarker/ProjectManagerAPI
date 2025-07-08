using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class ProjectPerUser
    {
        [Key]
        public int intProjectID { get; set; }
        public string strProjectName { get; set; }
        public DateOnly dteDeadLine { get; set; }
        public bool isCompleate { get; set; }
        public string Lenght { get; set; }
        public int UserCount { get; set; }
        public int TaskCount { get; set; }
    }
}
