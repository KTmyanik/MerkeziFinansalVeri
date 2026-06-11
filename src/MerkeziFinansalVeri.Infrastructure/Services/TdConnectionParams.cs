namespace MerkeziFinansalVeri.Infrastructure.Services;

public sealed class TdConnectionParams
{
    public string KatmanKodu { get; init; } = string.Empty;
    public string Sunucu { get; init; } = string.Empty;
    public string Veritabani { get; init; } = string.Empty;
    public int Port { get; init; } = 1433;
    public string KimlikDogrulama { get; init; } = "sql";
    public string? KullaniciAdi { get; init; }
}
