using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ProjectManagementAPI.Repository.Security;
using ProjectManagerAPI.Context;
using ProjectManagerAPI.Repository.Security;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddDbContext<ApplicationDBContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("TaskDB"))
);
builder.Services.AddDbContext<HRDBContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ERP_HR"))
);
builder.Services.AddScoped<IAPIValidation, APIValidation>();
builder.Services.AddScoped<IJWT, JWT>();

// Combine both authentication schemes if needed (optional)
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options => {
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };
})
.AddScheme<AuthenticationSchemeOptions, APIValidationHandler>("APIValidationScheme", null); // Optional if you want to keep custom validation

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("Boss", policy =>
        policy.RequireClaim("Boss", "True"));
});
builder.Services.AddHealthChecks();
var app = builder.Build();

// Configure the HTTP request pipeline.
app.MapHealthChecks("health");
app.UseSwagger();
app.UseSwaggerUI();

// Add authentication and authorization middleware
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
