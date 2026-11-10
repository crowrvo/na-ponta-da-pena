using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using VmsFinance.Infrastructure.Persistence;

namespace VmsFinance.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("VmsFinance");
        if (!string.IsNullOrWhiteSpace(connectionString))
        {
            services.AddDbContext<FinanceDbContext>(options => options.UseNpgsql(connectionString));
        }

        return services;
    }
}

