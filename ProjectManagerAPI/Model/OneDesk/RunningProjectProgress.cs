using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.OneDesk
{
    public class RunningProjectProgress
    {
        [Key]
        public int ID { get; set; }
        public string Team { get; set; } = string.Empty;
        public string Project { get; set; } = string.Empty;
        public int TasksCreated { get; set; }
        public int TasksCompleted { get; set; }
        public decimal ProgressPercent { get; set; }
        public string Status { get; set; } = string.Empty;
        public string Deadline { get; set; } = string.Empty;
        public string Aging { get; set; } = string.Empty;
        public string Person { get; set; } = string.Empty;
        public string KeyPerson { get; set; } = string.Empty;

    }
}
