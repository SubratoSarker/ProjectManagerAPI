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
    [Authorize]
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
        public async Task<List<ProjectPerUser>> GetProjectByUser(int Enroll, int Type)
        {
            try
            {
                var commandText = $"EXEC sprGetProjectByUser {Enroll}, {Type}";
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
        public async Task<IActionResult> CreateTask(string Name, string Description, string ReqFrom, int Priroty, DateOnly DeadLine, int Enroll, int Project)
        {
            try
            {
                // Define an output parameter to capture the message
                var msgParameter = new SqlParameter("@Msg", SqlDbType.VarChar, -1)
                {
                    Direction = ParameterDirection.Output
                };
                //@Priroty int,@DeadLine date,
                // Call the stored procedure asynchronously
                await _dbContext.Database.ExecuteSqlRawAsync(
                    "EXEC sprcreateTask @Name, @Description, @ReqFrom, @Priroty, @DeadLine, @Enroll, @Project, @Msg OUT",
                    new SqlParameter("@Name", Name),
                    new SqlParameter("@Description", Description),
                    new SqlParameter("@ReqFrom", ReqFrom),
                    new SqlParameter("@Priroty", Priroty),
                    new SqlParameter("@DeadLine", DeadLine),
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
        [HttpGet]
        [Route("GetTasks")]
        public async Task<List<Tasks>> GetTasks(int Enroll, int Status)
        {
            try
            {
                var commandText = $"EXEC sprGetTaskByUser {Enroll},{Status}";
                var result = _dbContext.Tasks.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("GetCurrentTasks")]
        public async Task<Tasks> GetCurrentTasks(int Enroll)
        {
            try
            {
                var commandText = $"EXEC sprGetTaskByUser {Enroll},{1}";
                var result = _dbContext.Tasks.FromSqlRaw(commandText).ToList().FirstOrDefault();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("GetStepsByTask")]
        public async Task<List<Steps>> GetStepsByTask(int Task)
        {
            try
            {
                var commandText = $"EXEC sprGetStepByTask {Task}";
                var result = _dbContext.Steps.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("TransferCheck")]
        public async Task<List<TransferUser>> TransferCheck(int Task, int User)
        {
            try
            {
                var commandText = $"EXEC sprTransferCheck {Task}, {User}";
                var result = _dbContext.TransferUser.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("StepManage")]
        public async Task<IActionResult> StepManage(int Type, string Name, bool IsDone, int StepID, int Enroll)
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
                    "EXEC sprUpdateStep @type, @Step, @isDone, @StepID, @Enroll, @Msg OUT",
                    new SqlParameter("@type", Type),
                    new SqlParameter("@Step", Name),
                    new SqlParameter("@isDone", IsDone),
                    new SqlParameter("@StepID", StepID),
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
        [Route("TaskManage")]
        public async Task<IActionResult> TaskManage(int Type, int TaskID, int User, int Status, TimeSpan Working, int Enroll)
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
                    "EXEC sprtaskManager @Type, @TaskID, @User, @Status, @tmTime, @Enroll, @Msg OUT",
                    new SqlParameter("@Type", Type),
                    new SqlParameter("@TaskID", TaskID),
                    new SqlParameter("@User", User),
                    new SqlParameter("@Status", Status),
                    new SqlParameter("@tmTime", Working),
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
        [Route("GetPerFormance")]
        public async Task<List<Performance>> GetPerFormance(DateTime From , DateTime To, int User, int Project)
        {
            try
            {
                var commandText = $"EXEC PerformanceReprot '{From}','{To}',{User},{Project}";
                var result = _dbContext.Performance.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("Request")]
        public async Task<IActionResult> Request(string TaskName, string Description, string RequestFrom, int USerID, int Project, DateTime Date, int Status, TimeSpan tm, string From, string To )
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
                    "EXEC sprRequestEntry @TaskName, @strDescription, @strRequestFrom, @intUserID, @intProjectID, @dteDate, @intStatusID, @tmWorking, @From, @To, @Msg OUT",
                    new SqlParameter("@TaskName", TaskName),
                    new SqlParameter("@strDescription", Description),
                    new SqlParameter("@strRequestFrom", RequestFrom),
                    new SqlParameter("@intUserID", USerID),
                    new SqlParameter("@intProjectID", Project),
                    new SqlParameter("@dteDate", Date),
                    new SqlParameter("@intStatusID", Status),
                    new SqlParameter("@tmWorking", tm),
                    new SqlParameter("@From", From),
                    new SqlParameter("@To", To),
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
        [Route("GetRequestList")]
        public async Task<List<Request>> GetRequestList(int User, Boolean isSuperviser)
        {
            try
            {
                var commandText = $"EXEC sprGetRequestList {User},{isSuperviser}";
                var result = _dbContext.Request.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("GetNotify")]
        public async Task<List<Notify>> GetNotify(int Enroll)
        {
            try
            {
                var commandText = $"EXEC sprGetNotify {Enroll}";
                var result = _dbContext.Notify.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("GetPendingTasks")]
        public async Task<List<PendingTask>> GetPendingTasks(int Enroll)
        {
            try
            {
                var commandText = $"EXEC sprPendingReport {Enroll}";
                var result = _dbContext.PendingTask.FromSqlRaw(commandText).ToList();

                return result;
            }
            catch (Exception ex)
            {
                // Handle other exceptions
                return null;
            }
        }
        [HttpGet]
        [Route("GetTask")]
        public async Task<Tasks> GetTask(int TaskID)
        {
            try
            {
                var commandText = $"EXEC GetTask {TaskID}";
                var result = _dbContext.Tasks.FromSqlRaw(commandText).ToList().FirstOrDefault();

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
