using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.OneDesk;
using ProjectManagerAPI.Model.Task;
using System.Data;

namespace ProjectManagerAPI.Controllers.OneDesk
{
    //[Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class OneDeskController : ControllerBase
    {
        private readonly HRDBContext _dbContext;
        public OneDeskController(HRDBContext dbContext)
        {
            _dbContext = dbContext;
        }
        [HttpGet("GetEmployeeList")]
        public async Task<PagedResult<Employee>> GetEmployeeList(int page = 1, int pageSize = 10, string? name = null, string? designation = null)
        {
            try
            {
                // 1. Create output parameters
                var paramCurrentPage = new SqlParameter("@CurrentPage", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var paramPerPage = new SqlParameter("@Per_Page", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var paramTotal = new SqlParameter("@Total", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var paramLastPage = new SqlParameter("@Last_Page", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var paramFrom = new SqlParameter("@From", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var paramTo = new SqlParameter("@To", SqlDbType.Int) { Direction = ParameterDirection.Output };

                // 2. Input parameters for filtering
                var paramName = new SqlParameter("@Name", SqlDbType.VarChar, 200)
                {
                    Value = string.IsNullOrEmpty(name) ? DBNull.Value : name
                };
                var paramDesignation = new SqlParameter("@Designation", SqlDbType.VarChar, 200)
                {
                    Value = string.IsNullOrEmpty(designation) ? DBNull.Value : designation
                };

                // 3. Call the stored procedure
                var employees = await _dbContext.Employee
                    .FromSqlRaw(
                        @"EXEC erp_hr.dbo.sprOneDeskGetEmployeeList 
                        @PageNumber={0}, 
                        @PageSize={1}, 
                        @Name={2}, 
                        @Designation={3}, 
                        @CurrentPage={4} OUTPUT, 
                        @Per_Page={5} OUTPUT, 
                        @Total={6} OUTPUT, 
                        @Last_Page={7} OUTPUT, 
                        @From={8} OUTPUT, 
                        @To={9} OUTPUT",
                        page, pageSize, paramName, paramDesignation, paramCurrentPage, paramPerPage, paramTotal, paramLastPage, paramFrom, paramTo)
                    .ToListAsync();

                // 4. Map output parameters to paged result
                return new PagedResult<Employee>
                {
                    Current_Page = (int)paramCurrentPage.Value,
                    Data = employees,
                    Per_Page = (int)paramPerPage.Value,
                    Total = (int)paramTotal.Value,
                    Last_Page = (int)paramLastPage.Value,
                    From = (int)paramFrom.Value,
                    To = (int)paramTo.Value
                };
            }
            catch (Exception ex)
            {
                // Handle exception
                return new PagedResult<Employee>
                {
                    Current_Page = page,
                    Data = new List<Employee>(),
                    Per_Page = pageSize,
                    Total = 0,
                    Last_Page = 0,
                    From = 0,
                    To = 0
                };
            }
        }
        [HttpGet("GetNewEmployeeList")]
        public async Task<List<Employee>> GetNewEmployeeList()
        {
            try
            {
                // Call the stored procedure to get new employees
                var employees = await _dbContext.Employee
                    .FromSqlRaw(@"EXEC erp_hr.dbo.sprOneDeskGetNewEmployeeList")
                    .ToListAsync();

                return employees;
            }
            catch (Exception ex)
            {
                // Optionally log the exception
                return new List<Employee>();
            }
        }
    }
}