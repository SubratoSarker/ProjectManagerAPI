namespace ProjectManagerAPI.Model.User
{
    public class LogInRequest
    {
        public string UserName { get; set; }
        public string PassWord { get; set; }
        public int Type { get; set; }
        public string Code { get; set; }
    }
}
