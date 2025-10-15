using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.OneDesk;
using ProjectManagerAPI.Model.Task;
using ProjectManagerAPI.Repository.Profile;
using System.Data;

namespace ProjectManagerAPI.Controllers.OneDesk
{
    //[Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class OneDeskController : ControllerBase
    {
        private readonly ApplicationDBContext _proj;
        private readonly HRDBContext _dbContext;
        public OneDeskController(HRDBContext dbContext, ApplicationDBContext proj)
        {
            _dbContext = dbContext;
            _proj = proj;
        }
        [HttpGet("GetEmployeeList")]
        public async Task<PagedResult<Employee>> GetEmployeeList(int page = 1, int pageSize = 10, string? search = null, string? designation = null, string? blood = null)
        {
            try
            {
                var fileApi = new FileAPI();
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
                    Value = string.IsNullOrEmpty(search) ? DBNull.Value : search
                };
                var paramDesignation = new SqlParameter("@Department", SqlDbType.VarChar, 200)
                {
                    Value = string.IsNullOrEmpty(designation) ? DBNull.Value : designation
                };
                var paramBlood = new SqlParameter("@Blood", SqlDbType.VarChar, 200)
                {
                    Value = string.IsNullOrEmpty(blood) ? DBNull.Value : blood
                };

                // 3. Call the stored procedure
                var employees = await _dbContext.Employee
                    .FromSqlRaw(
                        @"EXEC erp_hr.dbo.sprOneDeskGetEmployeeList 
                        @PageNumber={0}, 
                        @PageSize={1}, 
                        @Search={2}, 
                        @Department={3}, 
                        @Blood={4},
                        @CurrentPage={5} OUTPUT, 
                        @Per_Page={6} OUTPUT, 
                        @Total={7} OUTPUT, 
                        @Last_Page={8} OUTPUT, 
                        @From={9} OUTPUT, 
                        @To={10} OUTPUT",
                        page, pageSize, paramName, paramDesignation, paramBlood, paramCurrentPage, paramPerPage, paramTotal, paramLastPage, paramFrom, paramTo)
                    .ToListAsync();
                foreach (var employee in employees)
                {
                    try
                    {
                        var (photoBytes, fileName) = await fileApi.GetSingleFileFromBase64Async(employee.Enroll.ToString());

                        // 3. Assign photo bytes to employee.Photo
                        employee.Photo = photoBytes ?? Array.Empty<byte>();
                        employee.PFileName = fileName;
                    }
                    catch
                    {
                        // Handle per-employee errors individually
                        employee.Photo = Array.Empty<byte>();
                    }
                }

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
                var fileApi = new FileAPI();
                // Call the stored procedure to get new employees
                var employees = await _dbContext.Employee
                    .FromSqlRaw(@"EXEC erp_hr.dbo.sprOneDeskGetNewEmployeeList")
                    .ToListAsync();
                foreach (var employee in employees)
                {
                    try
                    {
                        var (photoBytes, fileName) = await fileApi.GetSingleFileFromBase64Async(employee.Enroll.ToString());

                        // 3. Assign photo bytes to employee.Photo
                        employee.Photo = photoBytes ?? Array.Empty<byte>();
                        employee.PFileName = fileName;
                    }
                    catch
                    {
                        // Handle per-employee errors individually
                        employee.Photo = Array.Empty<byte>();
                    }
                }

                return employees;
            }
            catch (Exception ex)
            {
                // Optionally log the exception
                return new List<Employee>();
            }
        }
        [HttpGet("CheckHealth")]
        public async Task<IActionResult> CheckHealth()
        {
            var fileApi = new FileAPI();

            // 1. Check DB connection
            try
            {
                var canConnect = await _dbContext.Database.CanConnectAsync();
                if (!canConnect)
                    return StatusCode(500, "Database connection failed.");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Database connection error: {ex.Message}");
            }

            // 2. Check File API
            try
            {
                var token = await fileApi.GetTokenAsync(); // returns null if fails
                if (string.IsNullOrEmpty(token))
                    return StatusCode(500, "File API connection failed.");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"File API connection error: {ex.Message}");
            }

            return Ok("All systems are operational.");
        }
        [HttpGet("GetTeamProjectProgress")]
        [AllowAnonymous]
        public async Task<ActionResult<List<RunningProjectProgress>>> GetTeamProjectProgress()
        {
            try
            {
                var report = await _proj.RunningProjectProgress
                    .FromSqlRaw("EXEC ProjectManagement.dbo.sprTeamProjectDynamicProgress")
                    .ToListAsync();

                return Ok(report);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error fetching progress report", error = ex.Message });
            }
        }

    }
}