using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.ProjectModel;
using ProjectManagerAPI.Repository.Security;
using System.Data;
using System.Numerics;

namespace ProjectManagerAPI.Controllers.Project
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class ProjectController : ControllerBase
    {
        private readonly ApplicationDBContext _dbContext;
        public ProjectController(ApplicationDBContext dbContext)
        {
            _dbContext = dbContext;
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
                    "EXEC sprCreateProject @Name, @Enroll, @Msg OUT",
                    new SqlParameter("@Name", Name),
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
        [Route("GetProjectByTeam")]
        public async Task<List<Projects>> GetProjectByTeam(int TeamID, int Enroll)
        {
            try
            {
                var commandText = $"EXEC sprGetProjectsByTeam {TeamID},{Enroll}";
                var result = _dbContext.Projects.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("StausUpdate")]
        public async Task<IActionResult> StausUpdate(int Type, int Project, int Enroll)
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
                    "EXEC sprUpdateProjectStatus @Type, @intProject, @Enroll, @Msg OUT",
                    new SqlParameter("@Type", Type),
                    new SqlParameter("@intProject", Project),
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
        [Route("UserPerProject")]
        public async Task<List<UserPerProject>> UserPerProject(int TeamID, int ProjectID)
        {
            try
            {
                var commandText = $"EXEC sprGetUserPerProject {TeamID},{ProjectID}";
                var result = _dbContext.UserPerProject.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("ProjectAssign")]
        public async Task<IActionResult> ProjectAssign(int User, int Project, bool Active, int Enroll)
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
                    "EXEC sprAssignUser @User, @Project, @Active, @Enroll, @Msg OUT",
                    new SqlParameter("@User", User),
                    new SqlParameter("@Project", Project),
                    new SqlParameter("@Active", Active),
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
    }
}
