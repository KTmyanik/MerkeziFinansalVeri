using MerkeziFinansalVeri.Api.Dtos;
using MerkeziFinansalVeri.Infrastructure.Configuration;
using MerkeziFinansalVeri.Infrastructure.Data;
using MerkeziFinansalVeri.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace MerkeziFinansalVeri.Api.Controllers;

[ApiController]
[Route("api/veri-kaynaklari")]
public class VeriKaynagiController(
    AppDbContext dbContext,
    ITdConnectionService tdConnectionService,
    IOptions<TdConnectionsOptions> tdOptions,
    IActivityLogService activityLogService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<VeriKaynagiDto>>> GetList(CancellationToken cancellationToken)
    {
        var entities = await dbContext.VeriKaynaklari
            .AsNoTracking()
            .OrderBy(v => v.KatmanKodu)
            .ToListAsync(cancellationToken);

        var items = entities.Select(ToDto).ToList();
        return Ok(items);
    }

    [HttpPut("{kaynakId:int}")]
    public async Task<ActionResult<VeriKaynagiDto>> Update(
        int kaynakId,
        [FromBody] VeriKaynagiUpdateDto dto,
        CancellationToken cancellationToken)
    {
        var entity = await dbContext.VeriKaynaklari
            .FirstOrDefaultAsync(v => v.KaynakId == kaynakId, cancellationToken);

        if (entity is null)
        {
            return NotFound();
        }

        entity.Sunucu = dto.Sunucu;
        entity.Veritabani = dto.Veritabani;
        entity.Port = dto.Port;
        entity.KimlikDogrulama = dto.KimlikDogrulama;
        entity.KullaniciAdi = dto.KullaniciAdi;
        entity.GuncellemeZamani = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);
        await activityLogService.LogAsync("veri_kaynagi", "Veri kaynağı güncellendi", entity.KatmanKodu, HttpContext.GetCurrentUserId(), cancellationToken);

        return Ok(ToDto(entity));
    }

    [HttpPost("{kaynakId:int}/test")]
    public async Task<ActionResult<VeriKaynagiTestSonucDto>> Test(
        int kaynakId,
        [FromBody] VeriKaynagiUpdateDto? dto,
        CancellationToken cancellationToken)
    {
        var entity = await dbContext.VeriKaynaklari
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.KaynakId == kaynakId, cancellationToken);

        if (entity is null)
        {
            return NotFound();
        }

        bool basarili;

        if (dto is not null && !string.IsNullOrWhiteSpace(dto.Sunucu))
        {
            basarili = await tdConnectionService.TestConnectionAsync(new TdConnectionParams
            {
                KatmanKodu = entity.KatmanKodu,
                Sunucu = dto!.Sunucu,
                Veritabani = dto.Veritabani,
                Port = dto.Port,
                KimlikDogrulama = dto.KimlikDogrulama,
                KullaniciAdi = dto.KullaniciAdi
            }, cancellationToken);
        }
        else
        {
            basarili = await tdConnectionService.TestConnectionAsync(entity.KatmanKodu, cancellationToken);
        }

        var kaynak = await dbContext.VeriKaynaklari
            .FirstOrDefaultAsync(v => v.KaynakId == kaynakId, cancellationToken);
        if (kaynak is not null)
        {
            kaynak.Durum = basarili ? "connected" : "error";
            kaynak.GuncellemeZamani = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Ok(new VeriKaynagiTestSonucDto
        {
            KatmanKodu = entity.KatmanKodu,
            Basarili = basarili,
            Mesaj = basarili ? "Bağlantı başarılı." : "Bağlantı başarısız. Sunucu, veritabanı ve kimlik doğrulama bilgilerini kontrol edin."
        });
    }

    private VeriKaynagiDto ToDto(Domain.Entities.VeriKaynagi v)
    {
        var dto = new VeriKaynagiDto
        {
            KaynakId = v.KaynakId,
            KatmanKodu = v.KatmanKodu,
            Sunucu = v.Sunucu,
            Veritabani = v.Veritabani,
            Port = v.Port,
            KimlikDogrulama = v.KimlikDogrulama,
            KullaniciAdi = v.KullaniciAdi,
            SifreSaklandi = v.SifreSaklandi,
            Durum = v.Durum,
            GuncellemeZamani = v.GuncellemeZamani
        };

        if (tdOptions.Value.Connections.TryGetValue(v.KatmanKodu, out var entry)
            && (string.IsNullOrWhiteSpace(dto.Sunucu) || dto.Sunucu.Contains("sirket.local", StringComparison.OrdinalIgnoreCase)))
        {
            dto.Sunucu = entry.Server;
            dto.Veritabani = entry.Database;
            dto.Port = entry.Port;
            dto.KimlikDogrulama = entry.KimlikDogrulama;
            dto.KullaniciAdi = entry.Username ?? dto.KullaniciAdi;
        }

        return dto;
    }
}
