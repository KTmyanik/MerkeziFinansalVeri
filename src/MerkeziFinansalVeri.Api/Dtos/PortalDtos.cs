namespace MerkeziFinansalVeri.Api.Dtos;

public sealed class PortalOzetDto
{
    public PortalKpiDto Kpi { get; set; } = new();
    public IReadOnlyList<EkipIlerlemeDto> EkipIlerleme { get; set; } = [];
    public IReadOnlyList<AktiviteLogDto> SonAktiviteler { get; set; } = [];
    public IReadOnlyList<EkipIsYukuDto> EkipIsYuku { get; set; } = [];
    public SistemDurumuDto SistemDurumu { get; set; } = new();
}

public sealed class PortalKpiDto
{
    public int KurumsalHesapSayisi { get; set; }
    public int MutabakatDonemSayisi { get; set; }
    public int AcikFarkSayisi { get; set; }
    public int BekleyenGorevSayisi { get; set; }
}

public sealed class EkipIlerlemeDto
{
    public int EkipId { get; set; }
    public string EkipAdi { get; set; } = string.Empty;
    public int ToplamFark { get; set; }
    public int KapatilanFark { get; set; }
    public int IlerlemeYuzde { get; set; }
}

public sealed class EkipIsYukuDto
{
    public int EkipId { get; set; }
    public string EkipAdi { get; set; } = string.Empty;
    public int AcikFarkSayisi { get; set; }
    public int BekleyenAksiyonSayisi { get; set; }
}

public sealed class SistemDurumuDto
{
    public IReadOnlyList<VeriKaynagiDurumDto> VeriKaynaklari { get; set; } = [];
}

public sealed class VeriKaynagiDurumDto
{
    public string KatmanKodu { get; set; } = string.Empty;
    public string Durum { get; set; } = string.Empty;
}

public sealed class VeriKalitesiKuralDto
{
    public string KuralId { get; set; } = string.Empty;
    public string Ad { get; set; } = string.Empty;
    public string Alan { get; set; } = string.Empty;
    public string Onem { get; set; } = string.Empty;
    public string Durum { get; set; } = string.Empty;
}

public sealed class VkKurallarAyarDto
{
    public string KatmanKodu { get; set; } = "TDUTIL";
    public string SorguDosyasi { get; set; } = "config/queries/vk-kurallar.sql";
    public int MaxSatir { get; set; } = 5000;
    public int SorguTimeoutSaniye { get; set; } = 120;
}

public sealed class VkGunlukSonuclarAyarDto
{
    public string KatmanKodu { get; set; } = "TDUTIL";
    public string SorguDosyasi { get; set; } = "config/queries/vk-gunluk-sonuclar.sql";
    public int MaxSatir { get; set; } = 5000;
    public int SorguTimeoutSaniye { get; set; } = 120;
}

public sealed class VeriKalitesiGunlukSonucDto
{
    public DateOnly CalistirmaTarihi { get; set; }
    public string KuralId { get; set; } = string.Empty;
    public string? KuralAdi { get; set; }
    public int GecenSayi { get; set; }
    public int HataliSayi { get; set; }
    public string Sonuc { get; set; } = string.Empty;
}

public sealed class VeriKaynagiDto
{
    public int KaynakId { get; set; }
    public string KatmanKodu { get; set; } = string.Empty;
    public string Sunucu { get; set; } = string.Empty;
    public string Veritabani { get; set; } = string.Empty;
    public int Port { get; set; }
    public string KimlikDogrulama { get; set; } = string.Empty;
    public string? KullaniciAdi { get; set; }
    public bool SifreSaklandi { get; set; }
    public string Durum { get; set; } = string.Empty;
    public DateTime GuncellemeZamani { get; set; }
}

public sealed class VeriKaynagiUpdateDto
{
    public string Sunucu { get; set; } = string.Empty;
    public string Veritabani { get; set; } = string.Empty;
    public int Port { get; set; } = 1433;
    public string KimlikDogrulama { get; set; } = "sql";
    public string? KullaniciAdi { get; set; }
}

public sealed class VeriKaynagiTestSonucDto
{
    public string KatmanKodu { get; set; } = string.Empty;
    public bool Basarili { get; set; }
    public string Mesaj { get; set; } = string.Empty;
}

public sealed class AktiviteLogDto
{
    public int LogId { get; set; }
    public string OlayTipi { get; set; } = string.Empty;
    public string Baslik { get; set; } = string.Empty;
    public string? Detay { get; set; }
    public int? KullaniciId { get; set; }
    public string? KullaniciAdi { get; set; }
    public DateTime OlusturmaZamani { get; set; }
}
