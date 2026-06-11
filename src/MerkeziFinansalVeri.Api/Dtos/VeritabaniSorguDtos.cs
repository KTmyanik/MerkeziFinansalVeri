namespace MerkeziFinansalVeri.Api.Dtos;

public sealed class VeritabaniSorguRequestDto
{
    public string KatmanKodu { get; set; } = "TDSTG";
    public string Sql { get; set; } = string.Empty;
}

public sealed class VeritabaniSorguSonucDto
{
    public bool Basarili { get; set; }
    public string? Hata { get; set; }
    public IReadOnlyList<string> Kolonlar { get; set; } = [];
    public IReadOnlyList<Dictionary<string, object?>> Satirlar { get; set; } = [];
    public int SatirSayisi { get; set; }
    public int SureMs { get; set; }
    public bool Kisitlandi { get; set; }
    public int MaxSatir { get; set; }
}

public sealed class VeritabaniSorguKatmanDto
{
    public string KatmanKodu { get; set; } = string.Empty;
    public string Sunucu { get; set; } = string.Empty;
    public int Port { get; set; } = 1433;
    public string Veritabani { get; set; } = string.Empty;
    public string KimlikDogrulama { get; set; } = "windows";
}

public sealed class VeritabaniSorguAyarDto
{
    public string VarsayilanKatman { get; set; } = "TDSTG";
    public int MaxSatir { get; set; } = 5000;
    public int SorguTimeoutSaniye { get; set; } = 120;
    public string VarsayilanSorgu { get; set; } = string.Empty;
    public string ConfigDosyasi { get; set; } = "config/td-connections.json";
    public IReadOnlyList<VeritabaniSorguKatmanDto> Katmanlar { get; set; } = [];
}
