using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class TaskTemplate
    {
        [Key]
        public int intTemplateID { get; set; }
        public string strName { get; set; }
        public string strTaskName { get; set; }
        public string? strDescription { get; set; }
        public int intPriroty { get; set; }
        public DateTime dteCreated { get; set; }
        public int StepCount { get; set; }
    }
}
