using Microsoft.EntityFrameworkCore;
using ProjectManagementAPI.Model.Security;
using ProjectManagerAPI.Model.Admin;
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
        public ApplicationDBContext(DbContextOptions<ApplicationDBContext> options) : base(options)
        {
        }
    }
}
