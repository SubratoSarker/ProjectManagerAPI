using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using ProjectManagementAPI.Model.Security;
using ProjectManagerAPI.Context;

namespace ProjectManagerAPI.Repository.Security
{
    public class APIValidation:IAPIValidation

    {

        private readonly ApplicationDBContext _dbContext;
        public APIValidation(ApplicationDBContext dbContext)
        {
            _dbContext = dbContext;
        }
        public APIValidationResponse apiValidation(APIValidationRequest APIValidationRequest)
        {
            //bool canConnect = _dbContext.Database.CanConnect();
            var usernameParam = new SqlParameter("@USERNAME", APIValidationRequest.USERNAME);
            var passwordParam = new SqlParameter("@PASSWORD", APIValidationRequest.PASSWORD);

            var result = _dbContext.APIValidationResponse
                .FromSqlRaw("EXEC sprGetAPIValidationProject @USERNAME, @PASSWORD", usernameParam, passwordParam)
                .AsEnumerable() // Execute the query and perform composition on the client side
                .FirstOrDefault();

            return result;
        }
    }
}
