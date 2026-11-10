using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using VmsFinance.Infrastructure.Persistence;
using VmsFinance.Application.Abstractions;

namespace VmsFinance.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("VmsFinance")
            ?? "Host=localhost;Port=5432;Database=vms_finance;Username=vms_finance;Password=vms_finance_dev";

        services.AddDbContext<FinanceDbContext>(options => options.UseNpgsql(connectionString));
        services.AddScoped<IFinanceRepository, FinanceRepository>();

        return services;
    }
}

