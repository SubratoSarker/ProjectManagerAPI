using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.Admin;
using ProjectManagerAPI.Model.ProjectModel;
using ProjectManagerAPI.Repository.Security;
using System.Data;
using System.Numerics;

namespace ProjectManagerAPI.Controllers.Admin
{
    [Authorize(Roles = "Admin")]
    [Route("api/[controller]")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDBContext _dbContext;
        public AdminController(ApplicationDBContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("GetAllUser")]
        public async Task<List<AllUser>> GetAllUser(int UserID)
        {
            try
            {
                var commandText = $"EXEC sprGetAllUser {UserID}";
                var result = _dbContext.AllUser.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("GetAllTeam")]
        public async Task<List<Team>> GetAllTeam()
        {
            try
            {
                var commandText = $"EXEC sprGetTeam ";
                var result = _dbContext.Team.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("UpdateUser")]
        public async Task<IActionResult> UpdateUser(int User, string Name, string Phone, string Email, int Team, bool Active, bool isboss, int Enroll, bool Locked)
        {
            try
            {
                // Define an output parameter to capture the message
                var msgParameter = new SqlParameter("@Msg", SqlDbType.VarChar, -1)
                {
                    Direction = ParameterDirection.Output
                };

                // Call the stored procedure asynchronously
                await _dbContext.Database.ExecuteSqlRawAsync(
                    "EXEC sprUpdateUser @User, @Name, @Phone, @Email, @TeamiID, @isActive, @isBoss, @Enroll, @Locked,  @Msg OUT",
                    new SqlParameter("@User", User),
                    new SqlParameter("@Name", Name),
                    new SqlParameter("@Phone", Phone),
                    new SqlParameter("@Email", Email),
                    new SqlParameter("@TeamiID", Team),
                    new SqlParameter("@isActive", Active),
                    new SqlParameter("@isBoss", isboss),
                    new SqlParameter("@Locked", Locked),
                    new SqlParameter("@Enroll", Enroll),
                    msgParameter
                );

                var message = msgParameter.Value?.ToString();

                return new JsonResult(message);
            }
            catch (DbUpdateException dbEx)
            {
                return StatusCode(503, "Database temporarily unavailable.");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Database connection failed: {ex.Message}");
            }
        }
        [HttpGet]
        [Route("Create")]
        public async Task<IActionResult> Create(string Name, int Enroll)
        {
            try
            {
                // Define an output parameter to capture the message
                var msgParameter = new SqlParameter("@Msg", SqlDbType.VarChar, -1)
                {
                    Direction = ParameterDirection.Output
                };

                // Call the stored procedure asynchronously
                await _dbContext.Database.ExecuteSqlRawAsync(
                    "EXEC sprCreateTeam @Team, @Enroll, @Msg OUT",
                    new SqlParameter("@Team", Name),
                    new SqlParameter("@Enroll", Enroll),
                    msgParameter
                );

                // Retrieve the output parameter value
                var message = msgParameter.Value?.ToString();

                return new JsonResult(message);
            }
            catch (DbUpdateException dbEx)
            {
                // Handle specific database update exception
                return StatusCode(503, "Database temporarily unavailable.");
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return StatusCode(500, $"Database connection failed: {ex.Message}");
            }
        }
        [HttpGet]
        [Route("GetTeamReport")]
        public async Task<List<DateWiseReport>> GetTeamReport(int Enroll, DateTime From, DateTime To)
        {
            try
            {
                var commandText = $"EXEC PerformanceReprotTeam {Enroll}, '{From}', '{To}' ";
                var result = _dbContext.DateWiseReport.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("GetCompleatedReport")]
        public async Task<List<CompleatedReport>> GetCompleatedReport(DateTime From, DateTime To)
        {
            try
            {
                var commandText = $"EXEC sprGetCompleatedTask  '{From}', '{To}' ";
                var result = _dbContext.CompleatedReport.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
    }
}
