using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Model.User;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ProjectManagerAPI.Repository.Security
{
    public class JWT : IJWT
    {
        private readonly IConfiguration _configuration;
        public JWT(IConfiguration configuration)
        {
            _configuration = configuration;
        }
        public string JWTToken(LogInResponse res)
        {
            var Key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
            var creds = new SigningCredentials(Key, SecurityAlgorithms.HmacSha256);


            var claims = new[]
            {
                new Claim(ClaimTypes.Name, res.UserName),
                new Claim(ClaimTypes.NameIdentifier, ToString()),
                new Claim(ClaimTypes.Role, res.ISAdmin ? "Admin" : "User"),
                new Claim("TeamID", res.TeamID.ToString()),
                new Claim("TeamName", res.TeamName),
                new Claim("Boss", res.ISBoss.ToString()),
            };

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddHours(2),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
