using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Repository.Security;
using System;

namespace Controllers.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class TestController : ControllerBase
    {
        private readonly ApplicationDBContext _dbContext;
        private readonly IAPIValidation _apiValidation;

        public TestController(ApplicationDBContext dbContext, IAPIValidation apiValidation)
        {
            _dbContext = dbContext;
            _apiValidation = apiValidation;
        }

        [HttpGet]
        [Route("GetConStatus")]
        [AllowAnonymous]
        //[Authorize(AuthenticationSchemes = "APIValidationScheme")] // Require authentication
        public IActionResult Get()
        {
            try
            {
                bool conn= _dbContext.Database.CanConnect();
                return Ok("Database connection successful.");
            }
            catch (DbUpdateException dbEx)
            {
                // Log the exception details for debugging purposes
                // logger.LogError(dbEx, "Error during database connection");
                return StatusCode(503, "Database temporarily unavailable.");
            }
            catch (Exception ex)
            {
                // Log the exception details for debugging purposes
                // logger.LogError(ex, "Error during database connection");
                return StatusCode(500, $"Database connection failed: {ex.Message}");
            }
        }
        [HttpGet]
        [Route("GetStatus")]
        [AllowAnonymous]
        //[Authorize(AuthenticationSchemes = "APIValidationScheme")] // Require authentication
        public IActionResult GetStatus()
        {
            try
            {
                return Ok("API Working Properly");
            }
            catch (DbUpdateException dbEx)
            {
                // Log the exception details for debugging purposes
                // logger.LogError(dbEx, "Error during database connection");
                return StatusCode(503, "Database temporarily unavailable.");
            }
            catch (Exception ex)
            {
                // Log the exception details for debugging purposes
                // logger.LogError(ex, "Error during database connection");
                return StatusCode(500, $"Database connection failed: {ex.Message}");
            }
        }
    }
}
