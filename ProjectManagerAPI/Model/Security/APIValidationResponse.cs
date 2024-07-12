using System.ComponentModel.DataAnnotations;

namespace ProjectManagementAPI.Model.Security
{
    public class APIValidationResponse
    {
        [Key]
        public int ID { get; set; }
        public string USERNAME { get; set; }
        public string PASSWORD { get; set; }
    }
}
