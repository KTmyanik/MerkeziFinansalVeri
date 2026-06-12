using MerkeziFinansalVeri.Api.Dtos;
using MerkeziFinansalVeri.Infrastructure.Data;
using MerkeziFinansalVeri.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MerkeziFinansalVeri.Api.Controllers;

[ApiController]
[Route("api/veri-kalitesi")]
public class VeriKalitesiController(
    AppDbContext dbContext,
    ITdConnectionService tdConnectionService,
    IConfiguration configuration,
    IWebHostEnvironment environment,
    ILogger<VeriKalitesiController> logger) : ControllerBase
{
    private string RepoRoot => Path.GetFullPath(Path.Combine(environment.ContentRootPath, "..", ".."));

    [HttpGet("kurallar/ayarlar")]
    public ActionResult<VkKurallarAyarDto> GetKurallarAyarlar()
    {
        return Ok(new VkKurallarAyarDto
        {
            KatmanKodu = configuration["VkKurallar:KatmanKodu"] ?? "TDUTIL",
            SorguDosyasi = configuration["VkKurallar:SorguDosyasi"] ?? "config/queries/vk-kurallar.sql",
            MaxSatir = int.TryParse(configuration["VkKurallar:MaxSatir"], out var maxSatir) ? maxSatir : 5000,
            SorguTimeoutSaniye = int.TryParse(configuration["VkKurallar:SorguTimeoutSaniye"], out var timeout) ? timeout : 120
        });
    }

    [HttpGet("kurallar/sorgu")]
    public async Task<ActionResult<VeritabaniSorguSonucDto>> GetKurallarSorgu(CancellationToken cancellationToken)
    {
        var ayarlar = new VkKurallarAyarDto
        {
            KatmanKodu = configuration["VkKurallar:KatmanKodu"] ?? "TDUTIL",
            SorguDosyasi = configuration["VkKurallar:SorguDosyasi"] ?? "config/queries/vk-kurallar.sql",
            MaxSatir = int.TryParse(configuration["VkKurallar:MaxSatir"], out var maxSatir) ? maxSatir : 5000,
            SorguTimeoutSaniye = int.TryParse(configuration["VkKurallar:SorguTimeoutSaniye"], out var timeout) ? timeout : 120
        };

        var sqlPath = Path.Combine(RepoRoot, ayarlar.SorguDosyasi.Replace('/', Path.DirectorySeparatorChar));
        if (!System.IO.File.Exists(sqlPath))
        {
            return NotFound(new VeritabaniSorguSonucDto
            {
                Basarili = false,
                Hata = $"Sorgu dosyası bulunamadı: {ayarlar.SorguDosyasi}"
            });
        }

        string sql;
        try
        {
            sql = await System.IO.File.ReadAllTextAsync(sqlPath, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "VK kurallar sorgu dosyası okunamadı: {Path}", sqlPath);
            return StatusCode(500, new VeritabaniSorguSonucDto
            {
                Basarili = false,
                Hata = "Sorgu dosyası okunamadı."
            });
        }

        if (string.IsNullOrWhiteSpace(sql))
        {
            return BadRequest(new VeritabaniSorguSonucDto
            {
                Basarili = false,
                Hata = "Sorgu dosyası boş."
            });
        }

        var result = await tdConnectionService.ExecuteReadOnlyQueryAsync(
            ayarlar.KatmanKodu,
            sql,
            ayarlar.SorguTimeoutSaniye,
            ayarlar.MaxSatir,
            cancellationToken);

        return Ok(ToDto(result, ayarlar.MaxSatir));
    }

    [HttpGet("kurallar")]
    public async Task<ActionResult<IReadOnlyList<VeriKalitesiKuralDto>>> GetKurallar(CancellationToken cancellationToken)
    {
        var items = await dbContext.VeriKalitesiKurallari
            .AsNoTracking()
            .OrderBy(k => k.KuralId)
            .Select(k => new VeriKalitesiKuralDto
            {
                KuralId = k.KuralId,
                Ad = k.Ad,
                Alan = k.Alan,
                Onem = k.Onem,
                Durum = k.Durum
            })
            .ToListAsync(cancellationToken);

        return Ok(items);
    }

    [HttpGet("gunluk-sonuclar")]
    public async Task<ActionResult<IReadOnlyList<VeriKalitesiGunlukSonucDto>>> GetGunlukSonuclar(
        [FromQuery] DateOnly? tarih,
        [FromQuery] int gun = 7,
        CancellationToken cancellationToken = default)
    {
        var query = dbContext.VeriKalitesiKuralSonuclari
            .AsNoTracking()
            .Include(s => s.Kural)
            .AsQueryable();

        if (tarih.HasValue)
        {
            query = query.Where(s => s.CalistirmaTarihi == tarih.Value);
        }
        else
        {
            var minTarih = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-Math.Clamp(gun, 1, 90)));
            query = query.Where(s => s.CalistirmaTarihi >= minTarih);
        }

        var items = await query
            .OrderByDescending(s => s.CalistirmaTarihi)
            .ThenBy(s => s.KuralId)
            .Select(s => new VeriKalitesiGunlukSonucDto
            {
                CalistirmaTarihi = s.CalistirmaTarihi,
                KuralId = s.KuralId,
                KuralAdi = s.Kural.Ad,
                GecenSayi = s.GecenSayi,
                HataliSayi = s.HataliSayi,
                Sonuc = s.Sonuc
            })
            .ToListAsync(cancellationToken);

        return Ok(items);
    }

    private static VeritabaniSorguSonucDto ToDto(TdQueryResult result, int maxRows)
    {
        var kolonlar = result.Satirlar.Count > 0
            ? result.Satirlar[0].Keys.ToList()
            : (IReadOnlyList<string>)Array.Empty<string>();

        var kisitlandi = result.Basarili && result.SatirSayisi >= maxRows;

        return new VeritabaniSorguSonucDto
        {
            Basarili = result.Basarili,
            Hata = result.Hata,
            Kolonlar = kolonlar,
            Satirlar = result.Satirlar,
            SatirSayisi = result.SatirSayisi,
            SureMs = result.SureMs,
            Kisitlandi = kisitlandi,
            MaxSatir = maxRows
        };
    }
}
