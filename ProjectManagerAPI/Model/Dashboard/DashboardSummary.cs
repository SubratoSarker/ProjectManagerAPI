using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Dashboard
{
    public class DashboardSummary
    {
        [Key]
        public int intStatusID { get; set; }
        public string strStatus { get; set; }
        public int TaskCount { get; set; }
    }
}
