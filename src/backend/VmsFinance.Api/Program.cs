using Microsoft.AspNetCore.Authentication.JwtBearer;
using VmsFinance.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Authentication:Authority"];
        options.Audience = builder.Configuration["Authentication:Audience"];
        options.RequireHttpsMetadata = true;
    });
builder.Services.AddAuthorization();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    var requiredSettings = new[]
    {
        (Name: "ConnectionStrings:VmsFinance", Value: app.Configuration.GetConnectionString("VmsFinance")),
        (Name: "Authentication:Authority", Value: app.Configuration["Authentication:Authority"]),
        (Name: "Authentication:Audience", Value: app.Configuration["Authentication:Audience"]),
    };

    var missing = requiredSettings
        .Where(setting => string.IsNullOrWhiteSpace(setting.Value))
        .Select(setting => setting.Name)
        .ToArray();

    if (missing.Length > 0)
    {
        throw new InvalidOperationException(
            $"Production startup blocked. Missing secure settings: {string.Join(", ", missing)}");
    }

    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapHealthChecks("/health/live").AllowAnonymous();
app.MapGet("/", () => Results.Ok(new
{
    service = "VMS Finance API",
    status = "bootstrap",
    message = "Financial endpoints remain disabled until authentication is completed."
})).AllowAnonymous();

app.Run();

public partial class Program;

