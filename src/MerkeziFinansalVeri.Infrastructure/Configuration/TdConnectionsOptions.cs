namespace MerkeziFinansalVeri.Infrastructure.Configuration;

public sealed class TdConnectionsOptions
{
    public const string SectionName = "TdConnections";

    public Dictionary<string, TdConnectionEntry> Connections { get; set; } = new(StringComparer.OrdinalIgnoreCase);
}

public sealed class TdConnectionEntry
{
    public string Server { get; set; } = string.Empty;
    public string Database { get; set; } = string.Empty;
    public int Port { get; set; } = 1433;
    public string KimlikDogrulama { get; set; } = "sql";
    public string? Username { get; set; }
}

public sealed class SyncOptions
{
    public const string SectionName = "Sync";

    public bool FarkVerenEnabled { get; set; } = true;
}
