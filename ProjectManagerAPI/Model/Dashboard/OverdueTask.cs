using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Dashboard
{
    public class OverdueTask
    {
        [Key]
        public int intTaskID { get; set; }
        public string strTaskName { get; set; }
        public DateOnly dteDeadLine { get; set; }
        public string strProjectName { get; set; }
        public string strUserName { get; set; }
        public string strStatus { get; set; }
    }
}
