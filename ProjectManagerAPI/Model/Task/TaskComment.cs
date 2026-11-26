using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class TaskComment
    {
        [Key]
        public int intCommentID { get; set; }
        public int intTaskID { get; set; }
        public int intUserID { get; set; }
        public string strUserName { get; set; }
        public string strComment { get; set; }
        public DateTime dteCreated { get; set; }
    }
}
