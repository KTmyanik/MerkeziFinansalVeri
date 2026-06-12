using MerkeziFinansalVeri.Api.Middleware;
using MerkeziFinansalVeri.Infrastructure;
using MerkeziFinansalVeri.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

var repoRoot = Path.GetFullPath(Path.Combine(builder.Environment.ContentRootPath, "..", ".."));
var tdConfigPath = Path.Combine(repoRoot, "config", "td-connections.json");
if (File.Exists(tdConfigPath))
{
    builder.Configuration.AddJsonFile(tdConfigPath, optional: true, reloadOnChange: true);
}

var vkKurallarConfigPath = Path.Combine(repoRoot, "config", "vk-kurallar.json");
if (File.Exists(vkKurallarConfigPath))
{
    builder.Configuration.AddJsonFile(vkKurallarConfigPath, optional: true, reloadOnChange: true);
}

var vkGunlukConfigPath = Path.Combine(repoRoot, "config", "vk-gunluk-sonuclar.json");
if (File.Exists(vkGunlukConfigPath))
{
    builder.Configuration.AddJsonFile(vkGunlukConfigPath, optional: true, reloadOnChange: true);
}

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddInfrastructure(builder.Configuration);

builder.Services.AddCors(options =>
{
    options.AddPolicy("StaticFiles", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.AllowAnyOrigin()
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
        else
        {
            policy.WithOrigins(builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? [])
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
    });
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    try
    {
        var bootstrap = scope.ServiceProvider.GetRequiredService<VeriKaynagiBootstrap>();
        await bootstrap.EnsureSeededAsync();
    }
    catch (Exception ex)
    {
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        logger.LogWarning(ex, "Veri kaynağı bootstrap atlandı — veritabanı henüz hazır olmayabilir.");
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("StaticFiles");
app.UseMiddleware<CurrentUserMiddleware>();
app.UseStaticFiles();
app.MapControllers();

app.Run();
