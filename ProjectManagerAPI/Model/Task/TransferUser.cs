using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class TransferUser
    {
        [Key]
        public int intUserID { get; set; }
        public string strUserName { get; set; }
    }
}
