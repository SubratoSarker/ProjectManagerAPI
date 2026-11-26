using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.ProjectModel
{
    public class TimelineTask
    {
        [Key]
        public int intTaskID { get; set; }
        public string strTaskName { get; set; }
        public DateTime dteStart { get; set; }
        public DateOnly dteEnd { get; set; }
        public int intStatusID { get; set; }
        public string strStatus { get; set; }
    }
}
