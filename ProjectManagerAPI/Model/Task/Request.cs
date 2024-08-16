using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class Request
    {
        [Key]
        public int intID { get; set; }
        public string strUserName { get; set; }
        public string strProjectName { get; set; }
        public string Type { get; set; }
        public string strTaskName { get; set; }
        public string strDescription { get; set; }
        public string strRequestFrom { get; set; }
        public DateTime dteCreated{ get; set; }
        public string strFrom { get; set; }
        public string strTo { get; set; }
        public TimeSpan tmWorking { get; set; }

    }
}
