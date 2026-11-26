using Microsoft.EntityFrameworkCore;
using ProjectManagementAPI.Model.Security;
using ProjectManagerAPI.Model.Admin;
using ProjectManagerAPI.Model.Dashboard;
using ProjectManagerAPI.Model.OneDesk;
using ProjectManagerAPI.Model.ProjectModel;
using ProjectManagerAPI.Model.Task;
using ProjectManagerAPI.Model.User;

namespace ProjectManagerAPI.Context
{
    public class ApplicationDBContext : DbContext
    {
        public DbSet<APIValidationResponse> APIValidationResponse { get; set; }
        public DbSet<LogInResponse> LogInResponse { get; set; }
        public DbSet<Projects> Projects { get; set; }
        public DbSet<AllUser> AllUser { get; set; }
        public DbSet<Team> Team { get; set; }
        public DbSet<UserPerProject> UserPerProject { get; set; }
        public DbSet<ProjectPerUser> ProjectPerUser { get; set; }
        public DbSet<Tasks> Tasks { get; set; }
        public DbSet<Steps> Steps { get; set; }
        public DbSet<TransferUser> TransferUser { get; set; }
        public DbSet<Performance> Performance { get; set; }
        public DbSet<Request> Request { get; set; }
        public DbSet<Notify> Notify { get; set; }
        public DbSet<DateWiseReport> DateWiseReport { get; set; }
        public DbSet<PendingTask> PendingTask { get; set; }
        public DbSet<CompleatedReport> CompleatedReport { get; set; }
        public DbSet<RunningProjectProgress> RunningProjectProgress { get; set; }
        public DbSet<TaskComment> TaskComment { get; set; }
        public DbSet<TaskAttachment> TaskAttachment { get; set; }
        public DbSet<TaskDependency> TaskDependency { get; set; }
        public DbSet<SubtaskItem> SubtaskItem { get; set; }
        public DbSet<Milestone> Milestone { get; set; }
        public DbSet<DashboardSummary> DashboardSummary { get; set; }
        public DbSet<WorkloadItem> WorkloadItem { get; set; }
        public DbSet<ProjectProgress> ProjectProgress { get; set; }
        public DbSet<OverdueTask> OverdueTask { get; set; }
        public DbSet<TaskLabel> TaskLabel { get; set; }
        public DbSet<OffboardingUser> OffboardingUser { get; set; }
        public DbSet<OpenTask> OpenTask { get; set; }
        public DbSet<TimelineTask> TimelineTask { get; set; }
        public DbSet<ActivityLogEntry> ActivityLogEntry { get; set; }
        public DbSet<UpcomingMilestone> UpcomingMilestone { get; set; }
        public DbSet<TeamActivityMember> TeamActivityMember { get; set; }
        public DbSet<SearchResult> SearchResult { get; set; }
        public DbSet<Teammate> Teammate { get; set; }
        public DbSet<CalendarTask> CalendarTask { get; set; }
        public ApplicationDBContext(DbContextOptions<ApplicationDBContext> options) : base(options)
        {
        }
    }
}
