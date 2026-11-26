using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class TaskDependency
    {
        [Key]
        public int intDependencyID { get; set; }
        public int intTaskID { get; set; }
        public int intDependsOnTaskID { get; set; }
        public string strDependsOnTaskName { get; set; }
        public string strStatus { get; set; }
        public int intStatusID { get; set; }
    }
}
