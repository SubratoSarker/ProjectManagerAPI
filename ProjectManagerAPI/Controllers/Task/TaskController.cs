using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.ProjectModel;
using ProjectManagerAPI.Model.Task;
using ProjectManagerAPI.Repository.Security;
using System.Data;
using System.Numerics;

namespace ProjectManagerAPI.Controllers.Task
{
    [Route("api/[controller]")]
    [ApiController]
    public class TaskController : ControllerBase
    {
        private readonly ApplicationDBContext _dbContext;
        public TaskController(ApplicationDBContext dbContext)
        {
            _dbContext = dbContext;
        }
        [HttpGet]
        [Route("GetProjectByUser")]
        [AllowAnonymous]
        public async Task<List<ProjectPerUser>> GetProjectByUser(int Enroll)
        {
            try
            {
                var commandText = $"EXEC sprGetProjectByUser {Enroll}";
                var result = _dbContext.ProjectPerUser.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("CreateTask")]
        [AllowAnonymous]
        public async Task<IActionResult> CreateTask(string Name, string Description, string ReqFrom, int Enroll, int Project)
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
                    "EXEC sprcreateTask @Name, @Description, @ReqFrom, @Enroll, @Project, @Msg OUT",
                    new SqlParameter("@Name", Name),
                    new SqlParameter("@Description", Description),
                    new SqlParameter("@ReqFrom", ReqFrom),
                    new SqlParameter("@Enroll", Enroll),
                    new SqlParameter("@Project", Project),
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
    }
}
