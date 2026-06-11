using System.Diagnostics;
using MerkeziFinansalVeri.Domain.Entities;
using MerkeziFinansalVeri.Infrastructure.Configuration;
using MerkeziFinansalVeri.Infrastructure.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace MerkeziFinansalVeri.Infrastructure.Services;

public class TdConnectionService(
    AppDbContext dbContext,
    IOptions<TdConnectionsOptions> tdOptions,
    ILogger<TdConnectionService> logger) : ITdConnectionService
{
    private static readonly HashSet<string> ReadOnlyPrefixes =
    [
        "SELECT", "WITH", "EXEC", "EXECUTE"
    ];

    public Task<bool> TestConnectionAsync(string katmanKodu, CancellationToken cancellationToken = default)
        => TestConnectionInternalAsync(katmanKodu, null, cancellationToken);

    public Task<bool> TestConnectionAsync(TdConnectionParams parameters, CancellationToken cancellationToken = default)
        => TestConnectionInternalAsync(parameters.KatmanKodu, parameters, cancellationToken);

    public async Task<TdQueryResult> ExecuteReadOnlyQueryAsync(
        string katmanKodu,
        string sql,
        int timeoutSeconds = 30,
        int maxRows = 1000,
        CancellationToken cancellationToken = default)
    {
        if (!IsReadOnlyQuery(sql))
        {
            return new TdQueryResult { Hata = "Yalnızca okuma sorgularına izin verilir." };
        }

        var kaynak = await ResolveConnectionAsync(katmanKodu, null, cancellationToken);
        if (kaynak is null)
        {
            return new TdQueryResult { Hata = $"Veri kaynağı bulunamadı: {katmanKodu}" };
        }

        var sw = Stopwatch.StartNew();
        try
        {
            await using var connection = CreateConnection(kaynak);
            await connection.OpenAsync(cancellationToken);

            await using var command = connection.CreateCommand();
            command.CommandText = sql.Trim().TrimEnd(';');
            command.CommandTimeout = timeoutSeconds;

            var satirlar = new List<Dictionary<string, object?>>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            while (await reader.ReadAsync(cancellationToken) && satirlar.Count < maxRows)
            {
                var row = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                for (var i = 0; i < reader.FieldCount; i++)
                {
                    row[reader.GetName(i)] = reader.IsDBNull(i) ? null : FormatCell(reader.GetValue(i));
                }

                satirlar.Add(row);
            }

            sw.Stop();
            return new TdQueryResult
            {
                Satirlar = satirlar,
                SatirSayisi = satirlar.Count,
                SureMs = (int)sw.ElapsedMilliseconds
            };
        }
        catch (Exception ex)
        {
            sw.Stop();
            logger.LogWarning(ex, "TD sorgu hatası: {KatmanKodu}", katmanKodu);
            return new TdQueryResult
            {
                Hata = ex.Message,
                SureMs = (int)sw.ElapsedMilliseconds
            };
        }
    }

    private async Task<bool> TestConnectionInternalAsync(
        string katmanKodu,
        TdConnectionParams? overrideParams,
        CancellationToken cancellationToken)
    {
        var kaynak = await ResolveConnectionAsync(katmanKodu, overrideParams, cancellationToken);
        if (kaynak is null)
        {
            return false;
        }

        try
        {
            await using var connection = CreateConnection(kaynak);
            await connection.OpenAsync(cancellationToken);

            if (overrideParams is null)
            {
                await UpdateDurumAsync(katmanKodu, "connected", cancellationToken);
            }

            return true;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "TD bağlantı testi başarısız: {KatmanKodu}", katmanKodu);
            if (overrideParams is null)
            {
                await UpdateDurumAsync(katmanKodu, "error", cancellationToken);
            }

            return false;
        }
    }

    internal async Task<VeriKaynagi?> ResolveConnectionAsync(
        string katmanKodu,
        TdConnectionParams? overrideParams,
        CancellationToken cancellationToken)
    {
        if (overrideParams is not null)
        {
            return new VeriKaynagi
            {
                KatmanKodu = katmanKodu,
                Sunucu = overrideParams.Sunucu,
                Veritabani = overrideParams.Veritabani,
                Port = overrideParams.Port,
                KimlikDogrulama = overrideParams.KimlikDogrulama,
                KullaniciAdi = overrideParams.KullaniciAdi
            };
        }

        var fromDb = await dbContext.VeriKaynaklari
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.KatmanKodu == katmanKodu, cancellationToken);

        if (fromDb is not null && !string.IsNullOrWhiteSpace(fromDb.Sunucu))
        {
            return fromDb;
        }

        if (tdOptions.Value.Connections.TryGetValue(katmanKodu, out var entry))
        {
            return new VeriKaynagi
            {
                KatmanKodu = katmanKodu,
                Sunucu = entry.Server,
                Veritabani = entry.Database,
                Port = entry.Port,
                KimlikDogrulama = entry.KimlikDogrulama,
                KullaniciAdi = entry.Username
            };
        }

        return fromDb;
    }

    private static SqlConnection CreateConnection(VeriKaynagi kaynak)
    {
        var builder = new SqlConnectionStringBuilder
        {
            DataSource = kaynak.Port == 1433 ? kaynak.Sunucu : $"{kaynak.Sunucu},{kaynak.Port}",
            InitialCatalog = kaynak.Veritabani,
            TrustServerCertificate = true,
            ApplicationIntent = ApplicationIntent.ReadOnly,
            ConnectTimeout = 15
        };

        if (string.Equals(kaynak.KimlikDogrulama, "windows", StringComparison.OrdinalIgnoreCase))
        {
            builder.IntegratedSecurity = true;
        }
        else
        {
            builder.UserID = kaynak.KullaniciAdi ?? string.Empty;
            builder.Password = string.Empty;
        }

        return new SqlConnection(builder.ConnectionString);
    }

    private async Task UpdateDurumAsync(string katmanKodu, string durum, CancellationToken cancellationToken)
    {
        var entity = await dbContext.VeriKaynaklari
            .FirstOrDefaultAsync(v => v.KatmanKodu == katmanKodu, cancellationToken);

        if (entity is null)
        {
            return;
        }

        entity.Durum = durum;
        entity.GuncellemeZamani = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static bool IsReadOnlyQuery(string sql)
    {
        var trimmed = sql.TrimStart();
        var firstWord = trimmed.Split([' ', '\r', '\n', '\t'], StringSplitOptions.RemoveEmptyEntries)[0];
        return ReadOnlyPrefixes.Contains(firstWord.ToUpperInvariant());
    }

    private static object? FormatCell(object value) => value switch
    {
        DateTime dt => dt.ToString("yyyy-MM-dd HH:mm:ss"),
        DateTimeOffset dto => dto.ToString("yyyy-MM-dd HH:mm:ss"),
        byte[] bytes => Convert.ToBase64String(bytes),
        _ => value
    };
}
