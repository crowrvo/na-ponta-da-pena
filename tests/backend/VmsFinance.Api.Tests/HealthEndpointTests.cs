using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Hosting;
using System.Net;
using System.Net.Http.Json;

namespace VmsFinance.Api.Tests;

public sealed class HealthEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
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
}

