using Microsoft.EntityFrameworkCore;
using ProjectManagementAPI.Model.Security;
using ProjectManagerAPI.Model.ProjectModel;
using ProjectManagerAPI.Model.User;

namespace ProjectManagerAPI.Context
{
    public class ApplicationDBContext : DbContext
    {
        public DbSet<APIValidationResponse> APIValidationResponse { get; set; }
        public DbSet<LogInResponse> LogInResponse { get; set; }
        public DbSet<Projects> Projects { get; set; }
        public DbSet<AllUser> AllUser { get; set; }
        public ApplicationDBContext(DbContextOptions<ApplicationDBContext> options) : base(options)
        {
        }
    }
}
