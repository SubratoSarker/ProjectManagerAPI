using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.Admin;

namespace ProjectManagerAPI.Controllers.Search
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class SearchController : ControllerBase
    {
        private readonly ApplicationDBContext _dbContext;
        public SearchController(ApplicationDBContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("Global")]
        public async Task<List<SearchResult>> Global(int Enroll, string Keyword)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(Keyword) || Keyword.Trim().Length < 2)
                {
                    return new List<SearchResult>();
                }
                // AsNoTracking is deliberate: Id is only unique WITHIN a ResultType (a Task row's Id
                // is a task id, a Comment row's Id is a comment id, etc.), so two different-typed rows
                // can legitimately share the same Id value. Without this, EF's identity map would key
                // purely off Id and silently collapse/drop rows that happen to collide.
                return await _dbContext.SearchResult
                    .FromSqlRaw("EXEC sprGlobalSearch {0}, {1}", Enroll, Keyword.Trim())
                    .AsNoTracking()
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                return null;
            }
        }
    }
}
