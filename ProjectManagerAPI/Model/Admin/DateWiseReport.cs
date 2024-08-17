using System.ComponentModel.DataAnnotations;
using System.Security.Principal;

namespace ProjectManagerAPI.Model.Admin
{
    public class DateWiseReport
    {
        [Key]
        public int ID { get; set; }
        public int intUserID { get; set; }
        public string strUserName { get; set; }
        public DateTime dteInsertDate { get; set; }
        public TimeSpan tmWorking { get; set; }
    }
}
