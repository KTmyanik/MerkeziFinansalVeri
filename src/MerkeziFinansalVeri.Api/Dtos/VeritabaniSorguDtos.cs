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
