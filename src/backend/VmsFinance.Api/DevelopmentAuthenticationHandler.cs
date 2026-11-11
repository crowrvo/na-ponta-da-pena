using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace VmsFinance.Api;

internal static class DevelopmentAuthenticationDefaults
{
    public const string Scheme = "VmsDevelopment";
}

internal sealed class DevelopmentAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder,
    IConfiguration configuration)
    : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var configuredToken = configuration["DevelopmentAuthentication:Token"];
        var userId = configuration["DevelopmentAuthentication:UserId"];
        if (string.IsNullOrWhiteSpace(configuredToken) || string.IsNullOrWhiteSpace(userId))
        {
            return Task.FromResult(AuthenticateResult.Fail("Development authentication is not configured."));
        }

        if (!Request.Headers.TryGetValue("Authorization", out var authorization)
            || authorization.Count != 1
            || !authorization[0]!.StartsWith("Bearer ", StringComparison.Ordinal))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var providedToken = authorization[0]!["Bearer ".Length..];
        var expectedBytes = Encoding.UTF8.GetBytes(configuredToken);
        var providedBytes = Encoding.UTF8.GetBytes(providedToken);
        if (expectedBytes.Length != providedBytes.Length
            || !CryptographicOperations.FixedTimeEquals(expectedBytes, providedBytes))
        {
            return Task.FromResult(AuthenticateResult.Fail("Invalid development access token."));
        }

        var identity = new ClaimsIdentity(
            [new Claim("sub", userId)],
            DevelopmentAuthenticationDefaults.Scheme);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, DevelopmentAuthenticationDefaults.Scheme);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
