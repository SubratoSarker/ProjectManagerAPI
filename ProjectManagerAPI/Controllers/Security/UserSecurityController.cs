using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.User;
using ProjectManagerAPI.Repository.Security;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ProjectManagerAPI.Controllers.Security
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserSecurityController : ControllerBase
    {
        private readonly ApplicationDBContext _dbContext;
        private readonly IAPIValidation _apiValidation;
        private readonly IConfiguration _configuration;
        private readonly IJWT _jwt;


        public UserSecurityController(ApplicationDBContext dbContext, IAPIValidation apiValidation, IConfiguration configuration, IJWT jwt)
        {
            _dbContext = dbContext;
            _apiValidation = apiValidation;
            _configuration = configuration;
            _jwt = jwt;
        }
        [HttpGet]
        [Route("SecurityCheck")]
        [Authorize(AuthenticationSchemes = "APIValidationScheme")]
        public IActionResult SecurityCheck(string Name,string Key,int Type, string Code)
        {
            try
            {
                LogInRequest req= new LogInRequest();
                req.UserName = Name;
                req.PassWord = Key;
                //req.PassWord = "Test";
                req.Type = Type;
                req.Code = Code;

                var result = _dbContext.LogInResponse
                    .FromSqlRaw($"EXEC sprSecurityCheck {req.Type},'{req.UserName}','{req.PassWord}','{req.Code}'")
                    .ToList();
                //var result = _dbContext.LogInResponse
                //.FromSqlRaw($"SELECT 1 AS UserID, 'Name' AS UserName, '0' AS Phone, 'E' AS Email, 1 AS TeamID, 'Team' AS TeamName, CAST(0 AS BIT) AS ISBoss, CAST(0 AS BIT) AS ISAdmin, 'a' AS Token, 'a' AS Response")
                //.AsEnumerable();

                if (result == null || !result.Any())
                {
                    return NotFound();
                }

                var response = result.First();

                // Check if Token is null
                if (response.Response == "GO")
                {
                    response.Token = _jwt.JWTToken(response);
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                // Log the exception for debugging purposes
                Console.WriteLine($"Error: {ex.Message}");

                // Return a 500 Internal Server Error status
                return StatusCode(500, "Internal Server Error");
            }
        }
        [HttpGet]
        [Route("Registration")]
        [Authorize(AuthenticationSchemes = "APIValidationScheme")]
        public IActionResult Registration(string Email, string Name, string Phone, string Key,int Team,int Enroll)
        {
            try
            {

                //var result = _dbContext.LogInResponse
                //       .FromSqlRaw($"EXEC sprRegistration '{Email}','{Name}','{Phone}','{Key}',{Team},{Enroll}")
                //       .ToList(); // Execute the query immediately and materialize the results
                var commandText = $"EXEC sprRegistration '{Email}','{Name}','{Phone}','{Key}',{Team},{Enroll}";
                var result = _dbContext.LogInResponse.FromSqlRaw(commandText).ToList();

                if (result == null)
                {
                    return NotFound();
                }

                var response = result.First();

                if (response.Response == "GO")
                {
                    response.Token = _jwt.JWTToken(response);
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                return StatusCode(500, "Internal Server Error");
            }
        }
    }
}
