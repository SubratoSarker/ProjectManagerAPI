using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.ProjectModel
{
    public class Milestone
    {
        [Key]
        public int intMilestoneID { get; set; }
        public int intProjectID { get; set; }
        public string strName { get; set; }
        public DateOnly dteDate { get; set; }
        public bool isCompleate { get; set; }
    }
}
