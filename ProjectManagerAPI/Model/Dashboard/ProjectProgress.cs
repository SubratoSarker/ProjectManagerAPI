using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Dashboard
{
    public class ProjectProgress
    {
        [Key]
        public int intProjectID { get; set; }
        public string strProjectName { get; set; }
        public int TotalTasks { get; set; }
        public int DoneTasks { get; set; }
    }
}
