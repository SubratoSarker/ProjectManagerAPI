using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Dashboard
{
    public class CalendarTask
    {
        [Key]
        public int intTaskID { get; set; }
        public string strTaskName { get; set; }
        public string strProjectName { get; set; }
        public DateOnly dteDeadLine { get; set; }
        public int intStatusID { get; set; }
        public string strStatus { get; set; }
        public string strUserName { get; set; }
    }
}
