using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using System.Net;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Security.Cryptography;

namespace VmsFinance.Api.Tests;

public sealed class HealthEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private const string Issuer = "https://issuer.example/";
    private const string Audience = "https://api.example/";
    private readonly WebApplicationFactory<Program> _factory;

    public HealthEndpointTests(WebApplicationFactory<Program> factory) => _factory = factory;

    [Fact]
    public async Task Live_health_endpoint_returns_success()
    {
        var client = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
        });

        var response = await client.GetAsync("/health/live");

        response.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Sync_endpoint_rejects_an_unauthenticated_request_before_accessing_data()
    {
        var client = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
        });

        var response = await client.PostAsJsonAsync(
            $"/api/households/{Guid.NewGuid()}/sync/entries",
            new { operations = Array.Empty<object>() });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Development_authentication_rejects_an_incorrect_token()
    {
        using var factory = _factory.WithWebHostBuilder(builder => builder
            .UseEnvironment("Development")
            .UseSetting("DevelopmentAuthentication:Enabled", "true")
            .UseSetting("DevelopmentAuthentication:Token", "test-only-token")
            .UseSetting("DevelopmentAuthentication:UserId", "local-test-user"));
        var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
        });

        using var rejected = new HttpRequestMessage(HttpMethod.Get, "/api/households");
        rejected.Headers.Authorization = new("Bearer", "wrong-token");
        var rejectedResponse = await client.SendAsync(rejected);

        Assert.Equal(HttpStatusCode.Unauthorized, rejectedResponse.StatusCode);
    }

    [Fact]
    public void Development_authentication_fails_closed_outside_development()
    {
        using var factory = _factory.WithWebHostBuilder(builder => builder
            .UseEnvironment("Production")
            .UseSetting("DevelopmentAuthentication:Enabled", "true")
            .UseSetting("DevelopmentAuthentication:Token", "test-only-token")
            .UseSetting("DevelopmentAuthentication:UserId", "local-test-user"));

        var exception = Assert.ThrowsAny<Exception>(() => factory.CreateClient());

        Assert.Contains(
            "Development authentication cannot be enabled outside the Development environment.",
            exception.ToString());
    }

    [Fact]
    public async Task Jwt_bearer_accepts_a_signed_token_with_expected_issuer_audience_and_subject()
    {
        using var rsa = RSA.Create(2048);
        var key = new RsaSecurityKey(rsa) { KeyId = "test-key" };
        using var factory = CreateJwtFactory(key);
        var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
        });
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/auth/session");
        request.Headers.Authorization = new("Bearer", CreateToken(key, Audience));

        var response = await client.SendAsync(request);

        response.EnsureSuccessStatusCode();
        var payload = await response.Content.ReadFromJsonAsync<AuthSessionResponse>();
        Assert.Equal("auth0|test-user", payload?.UserId);
    }

    [Fact]
    public async Task Jwt_bearer_rejects_a_token_for_another_audience()
    {
        using var rsa = RSA.Create(2048);
        var key = new RsaSecurityKey(rsa) { KeyId = "test-key" };
        using var factory = CreateJwtFactory(key);
        var client = factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
        });
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/auth/session");
        request.Headers.Authorization = new("Bearer", CreateToken(key, "https://other-api.example/"));

        var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private WebApplicationFactory<Program> CreateJwtFactory(SecurityKey signingKey) =>
        _factory.WithWebHostBuilder(builder => builder
            .UseEnvironment("Development")
            .UseSetting("Authentication:Authority", Issuer)
            .UseSetting("Authentication:Audience", Audience)
            .ConfigureTestServices(services => services.PostConfigure<JwtBearerOptions>(
                JwtBearerDefaults.AuthenticationScheme,
                options =>
                {
                    var configuration = new OpenIdConnectConfiguration
                    {
                        Issuer = Issuer,
                        SigningKeys = { signingKey },
                    };
                    options.Configuration = configuration;
                    options.ConfigurationManager =
                        new StaticConfigurationManager<OpenIdConnectConfiguration>(configuration);
                })));

    private static string CreateToken(SecurityKey signingKey, string audience) =>
        new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = Issuer,
            Audience = audience,
            Subject = new ClaimsIdentity([new Claim("sub", "auth0|test-user")]),
            IssuedAt = DateTime.UtcNow,
            Expires = DateTime.UtcNow.AddMinutes(5),
            SigningCredentials = new SigningCredentials(signingKey, SecurityAlgorithms.RsaSha256),
        });

    private sealed record AuthSessionResponse(string UserId);
}

