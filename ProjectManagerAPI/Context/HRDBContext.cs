using Microsoft.EntityFrameworkCore;
using ProjectManagerAPI.Model.OneDesk;

namespace ProjectManagerAPI.Context
{
    public class HRDBContext : DbContext
    {
        public DbSet<Employee> Employee { get; set; }
        public HRDBContext(DbContextOptions<HRDBContext> options) : base(options)
        {
        }
    }
}
