using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class TemplateStep
    {
        [Key]
        public int intTemplateStepID { get; set; }
        public int intTemplateID { get; set; }
        public string strStep { get; set; }
        public int intOrder { get; set; }
    }
}
