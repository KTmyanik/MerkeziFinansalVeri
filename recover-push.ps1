$ErrorActionPreference = 'Stop'
Set-Location 'C:\Users\mesut\MerkeziFinansalVeri'

Write-Host '=== Rebase temizligi ==='
Remove-Item '_push_log.txt', '_push_status.txt' -Force -ErrorAction SilentlyContinue
if ((Test-Path '.git\rebase-merge') -or (Test-Path '.git\rebase-apply')) {
    git rebase --abort
}

Write-Host '=== Uzak main aliniyor ==='
git fetch origin
git reset --mixed origin/main

Write-Host '=== Yerel degisiklikler commit ediliyor ==='
git add -A
$porcelain = git status --porcelain
if (-not $porcelain) {
    Write-Host 'Commit edilecek degisiklik yok. Zaten guncel olabilirsiniz.'
    git push -u origin main
    exit $LASTEXITCODE
}

git commit -m @"
Veritabani Sorgusu: harici config ve ayarlar endpoint

- config/td-connections.json ile sunucu/port yapilandirmasi
- VeritabaniSorguController ayarlar/calistir/test API
- veritabani-sorgu arayuzu ve push scriptleri
"@

Write-Host '=== Push ==='
git push -u origin main
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host ''
Write-Host 'Tamamlandi: https://github.com/KTmyanik/MerkeziFinansalVeri'
