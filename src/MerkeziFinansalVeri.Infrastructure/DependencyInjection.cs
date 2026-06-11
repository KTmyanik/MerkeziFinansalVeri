using MerkeziFinansalVeri.Infrastructure.Data;
using MerkeziFinansalVeri.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace MerkeziFinansalVeri.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

        services.AddScoped<IActivityLogService, ActivityLogService>();
        services.AddScoped<ITdConnectionService, TdConnectionService>();
        services.AddScoped<IPermissionService, PermissionService>();
        services.AddScoped<IFarkVerenSyncService>(sp => sp.GetRequiredService<FarkVerenSyncService>());

        if (configuration.GetValue("Sync:FarkVerenEnabled", true))
        {
            services.AddHostedService<FarkVerenSyncService>();
        }

        return services;
    }
}
