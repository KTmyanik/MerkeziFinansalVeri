using MerkeziFinansalVeri.Infrastructure.Configuration;
using MerkeziFinansalVeri.Infrastructure.Data;
using MerkeziFinansalVeri.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace MerkeziFinansalVeri.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<AppDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

        services.Configure<SyncOptions>(configuration.GetSection(SyncOptions.SectionName));
        services.Configure<TdConnectionsOptions>(options =>
        {
            var section = configuration.GetSection(TdConnectionsOptions.SectionName);
            foreach (var child in section.GetChildren())
            {
                var entry = child.Get<TdConnectionEntry>();
                if (entry is not null)
                {
                    options.Connections[child.Key] = entry;
                }
            }
        });

        services.AddScoped<IActivityLogService, ActivityLogService>();
        services.AddScoped<ITdConnectionService, TdConnectionService>();
        services.AddScoped<IPermissionService, PermissionService>();
        services.AddScoped<VeriKaynagiBootstrap>();
        services.AddScoped<IFarkVerenSyncService>(sp => sp.GetRequiredService<FarkVerenSyncService>());

        var syncEnabled = configuration.GetValue("Sync:FarkVerenEnabled", true);
        if (syncEnabled)
        {
            services.AddHostedService<FarkVerenSyncService>();
        }

        return services;
    }
}
