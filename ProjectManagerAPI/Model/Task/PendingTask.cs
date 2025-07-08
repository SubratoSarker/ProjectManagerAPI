using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class PendingTask
    {
        [Key]
        public int intTaskID { get; set; }
        public string strProjectName { get; set; }
        public string strTaskName { get; set; }
        public string strDescription { get; set; }
        public string strStatus { get; set; }
        public TimeSpan tmWorking { get; set; }
        public int intPriroty { get; set; }
        public DateOnly dteDeadLine { get; set; }
        public DateTime dteCreated { get; set; }
        public string strRequestFrom { get; set; }
    }
}
