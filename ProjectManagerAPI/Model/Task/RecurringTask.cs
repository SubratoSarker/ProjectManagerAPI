using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class RecurringTask
    {
        [Key]
        public int intRecurringID { get; set; }
        public string strTaskName { get; set; }
        public string? strDescription { get; set; }
        public int intPriroty { get; set; }
        public int intProjectID { get; set; }
        public string strProjectName { get; set; }
        public int intUserID { get; set; }
        public string strUserName { get; set; }
        public string strRecurrence { get; set; }
        public DateOnly dteNextRun { get; set; }
        public bool isActive { get; set; }
        public DateTime dteCreated { get; set; }
    }
}
