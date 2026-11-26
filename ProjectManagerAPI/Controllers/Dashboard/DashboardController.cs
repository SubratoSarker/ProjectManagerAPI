using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.Dashboard;
using ProjectManagerAPI.Model.ProjectModel;

namespace ProjectManagerAPI.Controllers.Dashboard
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController : ControllerBase
    {
        private readonly ApplicationDBContext _dbContext;
        public DashboardController(ApplicationDBContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("GetSummary")]
        public async Task<List<DashboardSummary>> GetSummary(int Enroll, int ProjectID = 0)
        {
            try
            {
                var commandText = $"EXEC sprGetDashboardSummary {Enroll},{ProjectID}";
                return _dbContext.DashboardSummary.FromSqlRaw(commandText).ToList();
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        [HttpGet]
        [Route("GetWorkload")]
        public async Task<List<WorkloadItem>> GetWorkload(int Enroll, int ProjectID = 0)
        {
            try
            {
                var commandText = $"EXEC sprGetWorkloadByTeam {Enroll},{ProjectID}";
                return _dbContext.WorkloadItem.FromSqlRaw(commandText).ToList();
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        [HttpGet]
        [Route("GetOverdue")]
        public async Task<List<OverdueTask>> GetOverdue(int Enroll, int ProjectID = 0)
        {
            try
            {
                var commandText = $"EXEC sprGetOverdueTasks {Enroll},{ProjectID}";
                return _dbContext.OverdueTask.FromSqlRaw(commandText).ToList();
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        [HttpGet]
        [Route("GetProjectProgress")]
        public async Task<List<ProjectProgress>> GetProjectProgress(int Enroll, int ProjectID = 0)
        {
            try
            {
                var commandText = $"EXEC sprGetProjectProgress {Enroll},{ProjectID}";
                return _dbContext.ProjectProgress.FromSqlRaw(commandText).ToList();
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        [HttpGet]
        [Route("GetTeamActivity")]
        public async Task<List<TeamActivityMember>> GetTeamActivity(int Enroll)
        {
            try
            {
                var commandText = $"EXEC sprGetTeamActivity {Enroll}";
                return _dbContext.TeamActivityMember.FromSqlRaw(commandText).ToList();
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        [HttpGet]
        [Route("GetUpcomingMilestones")]
        public async Task<List<UpcomingMilestone>> GetUpcomingMilestones(int Enroll)
        {
            try
            {
                var commandText = $"EXEC sprGetUpcomingMilestones {Enroll}";
                return _dbContext.UpcomingMilestone.FromSqlRaw(commandText).ToList();
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        [HttpGet]
        [Route("GetCalendarTasks")]
        public async Task<List<CalendarTask>> GetCalendarTasks(int Enroll, DateOnly From, DateOnly To)
        {
            try
            {
                return _dbContext.CalendarTask
                    .FromSqlRaw("EXEC sprGetCalendarTasks {0}, {1}, {2}", Enroll, From, To)
                    .ToList();
            }
            catch (Exception ex)
            {
                return null;
            }
        }
    }
}
