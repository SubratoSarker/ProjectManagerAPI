using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class SubtaskItem
    {
        [Key]
        public int intTaskID { get; set; }
        public string strTaskName { get; set; }
        public string strDescription { get; set; }
        public int intPriroty { get; set; }
        public DateOnly dteDeadLine { get; set; }
        public TimeSpan tmWorking { get; set; }
        public int intStatusID { get; set; }
        public string strStatus { get; set; }
    }
}
