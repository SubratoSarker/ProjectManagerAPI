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
        private readonly HRDBContext _hrDbContext;

        public UserSecurityController(ApplicationDBContext dbContext, IAPIValidation apiValidation, IConfiguration configuration, IJWT jwt, HRDBContext hrDbContext)
        {
            _dbContext = dbContext;
            _apiValidation = apiValidation;
            _configuration = configuration;
            _jwt = jwt;
            _hrDbContext = hrDbContext;
        }
        [HttpGet]
        [Route("SecurityCheck")]
        [Authorize(AuthenticationSchemes = "APIValidationScheme")]
        [AllowAnonymous]
        public async Task<IActionResult> SecurityCheck(string Name, string Key, int Type, string Code)
        {
            try
            {
                LogInRequest req = new LogInRequest();
                req.UserName = Name;
                req.PassWord = Key;
                req.Type = Type;
                req.Code = Code;

                var result = _dbContext.LogInResponse
                    .FromSqlRaw($"EXEC sprSecurityCheck {req.Type},'{req.UserName}','{req.PassWord}','{req.Code}'")
                    .ToList();

                if (result == null || !result.Any())
                {
                    return NotFound();
                }

                var response = result.First();

                if (response.Response == "GO")
                {
                    response.Token = _jwt.JWTToken(response);
                }
                else if (response.TeamName == "Otp Request" && response.UserName == "Otp Request")
                {
                    await _hrDbContext.Database.ExecuteSqlRawAsync(
                        "EXEC erp_hr.dbo.sprOTPSendAG @Phone={0}, @OTP={1}",
                        response.Phone,
                        response.Email);
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
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
