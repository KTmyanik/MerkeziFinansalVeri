# TDUTIL veritabani kurulumu
# SQL Server Management Studio veya sqlcmd ile calistirin.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$files = @(
    "database\migrations\001_initial_schema.sql",
    "database\seeds\001_ref_seed.sql",
    "database\seeds\002_sec_seed.sql",
    "database\seeds\003_ops_seed.sql",
    "database\seeds\004_cfg_seed.sql",
    "database\seeds\005_audit_seed.sql"
)

$server = if ($env:SQL_SERVER) { $env:SQL_SERVER } else { "srvdev\PASIFIK" }

Write-Host "Sunucu: $server"
Write-Host "Scriptler sirayla calistirilacak..."

foreach ($rel in $files) {
    $path = Join-Path $root $rel
    if (-not (Test-Path $path)) {
        Write-Error "Dosya bulunamadi: $path"
    }
    Write-Host "-> $rel"
    sqlcmd -S $server -E -i $path
    if ($LASTEXITCODE -ne 0) {
        Write-Error "sqlcmd hata verdi: $rel"
    }
}

Write-Host "Kurulum tamamlandi."
