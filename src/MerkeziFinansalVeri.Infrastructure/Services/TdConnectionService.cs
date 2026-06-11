using System.Diagnostics;
using MerkeziFinansalVeri.Domain.Entities;
using MerkeziFinansalVeri.Infrastructure.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace MerkeziFinansalVeri.Infrastructure.Services;

public class TdConnectionService(
    AppDbContext dbContext,
    IConfiguration configuration,
    ILogger<TdConnectionService> logger) : ITdConnectionService
{
    private static readonly HashSet<string> ReadOnlyPrefixes =
    [
        "SELECT", "WITH", "EXEC", "EXECUTE"
    ];

    public async Task<bool> TestConnectionAsync(string katmanKodu, CancellationToken cancellationToken = default)
    {
        var kaynak = await GetVeriKaynagiAsync(katmanKodu, cancellationToken);
        if (kaynak is null)
        {
            return false;
        }

        try
        {
            await using var connection = CreateConnection(kaynak);
            await connection.OpenAsync(cancellationToken);
            await UpdateDurumAsync(kaynak, "connected", cancellationToken);
            return true;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "TD bağlantı testi başarısız: {KatmanKodu}", katmanKodu);
            await UpdateDurumAsync(kaynak, "error", cancellationToken);
            return false;
        }
    }

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

        var kaynak = await GetVeriKaynagiAsync(katmanKodu, cancellationToken);
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
            command.CommandText = WrapWithRowLimit(sql, maxRows);
            command.CommandTimeout = timeoutSeconds;

            var satirlar = new List<Dictionary<string, object?>>();
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            while (await reader.ReadAsync(cancellationToken) && satirlar.Count < maxRows)
            {
                var row = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                for (var i = 0; i < reader.FieldCount; i++)
                {
                    row[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
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

    internal async Task<VeriKaynagi?> GetVeriKaynagiAsync(string katmanKodu, CancellationToken cancellationToken)
    {
        try
        {
            var fromDb = await dbContext.VeriKaynaklari
                .AsNoTracking()
                .FirstOrDefaultAsync(v => v.KatmanKodu == katmanKodu, cancellationToken);

            if (fromDb is not null)
            {
                return fromDb;
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "VeriKaynagi DB okunamadı, appsettings yedek kullanılacak: {KatmanKodu}", katmanKodu);
        }

        return GetKaynakFromConfig(katmanKodu);
    }

    private VeriKaynagi? GetKaynakFromConfig(string katmanKodu)
    {
        var section = configuration.GetSection($"TdConnections:{katmanKodu}");
        if (!section.Exists())
        {
            return null;
        }

        var server = section["Server"];
        var database = section["Database"];
        if (string.IsNullOrWhiteSpace(server) || string.IsNullOrWhiteSpace(database))
        {
            return null;
        }

        return new VeriKaynagi
        {
            KaynakId = 0,
            KatmanKodu = katmanKodu,
            Sunucu = server,
            Veritabani = database,
            Port = section.GetValue("Port", 1433),
            KimlikDogrulama = section["KimlikDogrulama"] ?? "windows",
            KullaniciAdi = section["KullaniciAdi"]
        };
    }

    private static SqlConnection CreateConnection(VeriKaynagi kaynak)
    {
        var builder = new SqlConnectionStringBuilder
        {
            DataSource = kaynak.Port == 1433 ? kaynak.Sunucu : $"{kaynak.Sunucu},{kaynak.Port}",
            InitialCatalog = kaynak.Veritabani,
            TrustServerCertificate = true,
            ApplicationIntent = ApplicationIntent.ReadOnly
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

    private async Task UpdateDurumAsync(VeriKaynagi kaynak, string durum, CancellationToken cancellationToken)
    {
        if (kaynak.KaynakId <= 0)
        {
            return;
        }

        var entity = await dbContext.VeriKaynaklari.FindAsync([kaynak.KaynakId], cancellationToken);
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

    private static string WrapWithRowLimit(string sql, int maxRows)
    {
        if (sql.Contains("TOP ", StringComparison.OrdinalIgnoreCase))
        {
            return sql;
        }

        return $"SELECT TOP ({maxRows}) * FROM ({sql.Trim().TrimEnd(';')}) AS q";
    }
}
