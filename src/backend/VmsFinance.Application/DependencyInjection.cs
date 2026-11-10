using Microsoft.Extensions.DependencyInjection;
using VmsFinance.Application.Finance;

namespace VmsFinance.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddSingleton(TimeProvider.System);
        services.AddScoped<FinanceService>();
        return services;
    }
}
