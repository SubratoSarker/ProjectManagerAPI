using Azure.Core;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text.Encodings.Web;
using System.Text;
using ProjectManagerAPI.Repository.Security;
using ProjectManagementAPI.Model.Security;

namespace ProjectManagementAPI.Repository.Security
{
    public class APIValidationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        private readonly IAPIValidation _apiValidation;

        public APIValidationHandler(
            IAPIValidation apiValidation,
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder,
            ISystemClock clock)
            : base(options, logger, encoder, clock)
        {
            _apiValidation = apiValidation;
        }

        protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            // Extract credentials from the request
            if (!Request.Headers.TryGetValue("Authorization", out var headerValue))
                return AuthenticateResult.Fail("Authorization header is missing.");

            var authHeaderValue = AuthenticationHeaderValue.Parse(headerValue);
            var credentialBytes = Convert.FromBase64String(authHeaderValue.Parameter);
            var credentials = Encoding.UTF8.GetString(credentialBytes).Split(':', 2);
            var username = credentials[0];
            var password = credentials[1];

            // Perform authentication
            var request = new APIValidationRequest { USERNAME = username, PASSWORD = password };
            var response = _apiValidation.apiValidation(request);

            // Check if authentication was successful
            if (response != null)
            {
                var claims = new[] {
                new Claim(ClaimTypes.Name, response.USERNAME),
                // Add additional claims as needed
            };
                var identity = new ClaimsIdentity(claims, Scheme.Name);
                var principal = new ClaimsPrincipal(identity);
                var ticket = new AuthenticationTicket(principal, Scheme.Name);

                return AuthenticateResult.Success(ticket);
            }

            return AuthenticateResult.Fail("Invalid username or password.");
        }
    }
}
