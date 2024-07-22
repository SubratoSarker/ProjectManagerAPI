using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class Steps
    {
        [Key]
        public int intStepId { get; set; }
        public string strStep { get; set; }
        public int intTaskID { get; set; }
        public Boolean isDone { get; set; }
    }
}
