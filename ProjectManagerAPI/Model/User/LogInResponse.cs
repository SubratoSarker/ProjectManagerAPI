using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.User
{
    public class LogInResponse
    {
        [Key]
        public int UserID { get; set; }
        public string UserName { get; set; }
        public string Phone { get; set; }
        public string Email { get; set; }   
        public int TeamID { get; set; }   
        public string TeamName { get; set; }   
        public bool ISBoss { get; set; }   
        public bool ISAdmin { get; set; }   
        public string Token { get; set;}
        public string Response { get; set;}
    }
}
