using ProjectManagementAPI.Model.Security;
using ProjectManagerAPI.Model.User;

namespace ProjectManagerAPI.Repository.Security
{
    public interface IJWT
    {
        public string JWTToken(LogInResponse res);

    }
}
