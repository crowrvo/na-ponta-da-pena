using Microsoft.AspNetCore.Authentication.JwtBearer;
using System.Security.Claims;
using System.Text.Json;
using System.Text.Json.Serialization;
using VmsFinance.Application;
using VmsFinance.Application.Common;
using VmsFinance.Application.Finance;
using VmsFinance.Domain.Finance;
using VmsFinance.Domain.Households;
using VmsFinance.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();
builder.Services.AddProblemDetails();
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase)));
builder.Services.AddApplication();
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

app.UseExceptionHandler(exceptionHandler => exceptionHandler.Run(async context =>
{
    var exception = context.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>()?.Error;
    var (status, title) = exception switch
    {
        ResourceNotFoundException => (StatusCodes.Status404NotFound, "Resource not found"),
        HouseholdAccessDeniedException => (StatusCodes.Status403Forbidden, "Household access denied"),
        IdempotencyConflictException => (StatusCodes.Status409Conflict, "Idempotency conflict"),
        ArgumentException => (StatusCodes.Status400BadRequest, "Invalid request"),
        _ => (StatusCodes.Status500InternalServerError, "Unexpected error"),
    };
    await Results.Problem(statusCode: status, title: title).ExecuteAsync(context);
}));

app.MapHealthChecks("/health/live").AllowAnonymous();
app.MapGet("/", () => Results.Ok(new
{
    service = "VMS Finance API",
    status = "bootstrap",
    message = "Financial endpoints remain disabled until authentication is completed."
})).AllowAnonymous();

var api = app.MapGroup("/api").RequireAuthorization();

api.MapPost("/households", async (CreateHouseholdRequest request, ClaimsPrincipal user, FinanceService service, CancellationToken ct) =>
{
    var result = await service.CreateHouseholdAsync(RequireUserId(user), request.Name, ct);
    return Results.Created($"/api/households/{result.Id}", result);
});

api.MapGet("/households", (ClaimsPrincipal user, FinanceService service, CancellationToken ct) =>
    service.ListHouseholdsAsync(RequireUserId(user), ct));

api.MapPost("/households/{householdId:guid}/members", async (Guid householdId, AddMemberRequest request, ClaimsPrincipal user, FinanceService service, CancellationToken ct) =>
{
    await service.AddMemberAsync(householdId, RequireUserId(user), request.UserId, request.Role, ct);
    return Results.NoContent();
});

api.MapPost("/households/{householdId:guid}/entries", async (Guid householdId, CreateEntryRequest request, ClaimsPrincipal user, FinanceService service, CancellationToken ct) =>
{
    var result = await service.CreateEntryAsync(householdId, RequireUserId(user), request.Id, request.Direction,
        request.AmountInCents, request.Description, request.OccurredOn, request.IdempotencyKey, ct);
    return result.Created
        ? Results.Created($"/api/households/{householdId}/entries/{result.Entry.Id}", result.Entry)
        : Results.Ok(result.Entry);
});

api.MapPost("/households/{householdId:guid}/sync/entries", async (Guid householdId, SyncEntriesRequest request, ClaimsPrincipal user, FinanceService service, CancellationToken ct) =>
{
    if (request.Operations is null)
    {
        return Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["operations"] = ["The operations field is required."],
        });
    }

    var commands = request.Operations
        .Select(entry => new SyncEntryCommand(entry.Id, entry.Direction, entry.AmountInCents,
            entry.Description, entry.OccurredOn, entry.IdempotencyKey))
        .ToArray();
    return Results.Ok(await service.SyncEntriesAsync(householdId, RequireUserId(user), commands, ct));
});

api.MapGet("/households/{householdId:guid}/entries", (Guid householdId, int year, int month, ClaimsPrincipal user, FinanceService service, CancellationToken ct) =>
    service.GetMonthlyEntriesAsync(householdId, RequireUserId(user), year, month, ct));

static string RequireUserId(ClaimsPrincipal user) =>
    user.FindFirstValue("sub") ?? user.FindFirstValue(ClaimTypes.NameIdentifier)
    ?? throw new HouseholdAccessDeniedException("Authenticated user id is missing.");

app.Run();

public partial class Program;

public sealed record CreateHouseholdRequest(string Name);
public sealed record AddMemberRequest(string UserId, HouseholdRole Role);
public sealed record CreateEntryRequest(Guid Id, EntryDirection Direction, long AmountInCents, string Description, DateOnly OccurredOn, string IdempotencyKey);
public sealed record SyncEntriesRequest(IReadOnlyList<CreateEntryRequest>? Operations);

