using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.ProjectModel
{
    public class Projects
    {
        [Key]
        public int IntProjectID { get; set; }
        public string StrProjectName { get; set; }
        public bool IsCompleate { get; set; }
        public string DaysPassed { get; set; }
        public int UserCount { get; set; }
    }
}
