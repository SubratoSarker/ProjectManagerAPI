using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class TaskAttachment
    {
        [Key]
        public int intAttachmentID { get; set; }
        public int intTaskID { get; set; }
        public int intUserID { get; set; }
        public string strUserName { get; set; }
        public string strFileName { get; set; }
        public string strRemotePath { get; set; }
        public string strContentType { get; set; }
        public long? intSizeBytes { get; set; }
        public DateTime dteUploaded { get; set; }
    }
}
