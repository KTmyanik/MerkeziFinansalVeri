using MerkeziFinansalVeri.Api.Dtos;
using MerkeziFinansalVeri.Domain.Entities;
using MerkeziFinansalVeri.Infrastructure.Data;
using MerkeziFinansalVeri.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;

namespace MerkeziFinansalVeri.Api.Controllers;

[ApiController]
[Route("api/veritabani-sorgu")]
public class VeritabaniSorguController(
    ITdConnectionService tdConnectionService,
    AppDbContext dbContext,
    IActivityLogService activityLogService,
    ILogger<VeritabaniSorguController> logger) : ControllerBase
{
    private const int MaxRows = 5000;
    private const int TimeoutSeconds = 120;

    [HttpPost("calistir")]
    public async Task<ActionResult<VeritabaniSorguSonucDto>> Calistir(
        [FromBody] VeritabaniSorguRequestDto dto,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(dto.Sql))
        {
            return BadRequest(new VeritabaniSorguSonucDto { Basarili = false, Hata = "Sorgu metni boş." });
        }

        var katman = string.IsNullOrWhiteSpace(dto.KatmanKodu) ? "TDSTG" : dto.KatmanKodu.Trim();
        var result = await tdConnectionService.ExecuteReadOnlyQueryAsync(
            katman,
            dto.Sql,
            TimeoutSeconds,
            MaxRows,
            cancellationToken);

        await TryLogExecutionAsync(katman, result, cancellationToken);

        if (!result.Basarili)
        {
            await TryActivityLogAsync(
                "veritabani_sorgu",
                "Sorgu hatası",
                $"{katman}: {result.Hata}",
                cancellationToken);

            return Ok(ToDto(result, kisitlandi: false));
        }

        await TryActivityLogAsync(
            "veritabani_sorgu",
            "Sorgu çalıştırıldı",
            $"{katman} — {result.SatirSayisi} satır, {result.SureMs} ms",
            cancellationToken);

        var kisitlandi = result.SatirSayisi >= MaxRows;
        return Ok(ToDto(result, kisitlandi));
    }

    [HttpPost("test/{katmanKodu}")]
    public async Task<ActionResult<VeriKaynagiTestSonucDto>> Test(string katmanKodu, CancellationToken cancellationToken)
    {
        var basarili = await tdConnectionService.TestConnectionAsync(katmanKodu, cancellationToken);
        return Ok(new VeriKaynagiTestSonucDto
        {
            KatmanKodu = katmanKodu,
            Basarili = basarili,
            Mesaj = basarili ? "Bağlantı başarılı." : "Bağlantı başarısız. Yönetim → Veritabanı Bağlantısı ayarlarını kontrol edin."
        });
    }

    private async Task TryLogExecutionAsync(string katman, TdQueryResult result, CancellationToken cancellationToken)
    {
        try
        {
            dbContext.SorguCalistirmaLoglari.Add(new SorguCalistirmaLog
            {
                KatmanKodu = katman,
                CalistirmaZamani = DateTime.UtcNow,
                SatirSayisi = result.Basarili ? result.SatirSayisi : null,
                SureMs = result.SureMs,
                Hata = result.Hata,
                KullaniciId = HttpContext.GetCurrentUserId()
            });

            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Sorgu çalıştırma logu yazılamadı (uygulama DB erişilemiyor olabilir).");
        }
    }

    private async Task TryActivityLogAsync(
        string olayTipi,
        string baslik,
        string? detay,
        CancellationToken cancellationToken)
    {
        try
        {
            await activityLogService.LogAsync(
                olayTipi,
                baslik,
                detay,
                HttpContext.GetCurrentUserId(),
                cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Aktivite logu yazılamadı.");
        }
    }

    private static VeritabaniSorguSonucDto ToDto(TdQueryResult result, bool kisitlandi)
    {
        var kolonlar = result.Satirlar.Count > 0
            ? result.Satirlar[0].Keys.ToList()
            : (IReadOnlyList<string>)Array.Empty<string>();

        return new VeritabaniSorguSonucDto
        {
            Basarili = result.Basarili,
            Hata = result.Hata,
            Kolonlar = kolonlar,
            Satirlar = result.Satirlar,
            SatirSayisi = result.SatirSayisi,
            SureMs = result.SureMs,
            Kisitlandi = kisitlandi,
            MaxSatir = MaxRows
        };
    }
}
