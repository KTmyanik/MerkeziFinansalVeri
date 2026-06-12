$ErrorActionPreference = 'Stop'
Set-Location 'C:\Users\mesut\MerkeziFinansalVeri'

Remove-Item '_push_log.txt', '_push_status.txt' -Force -ErrorAction SilentlyContinue
if ((Test-Path '.git\rebase-merge') -or (Test-Path '.git\rebase-apply')) {
    git rebase --abort
}

Write-Host '=== fetch ==='
git fetch origin

Write-Host '=== stage ==='
git add -A

$porcelain = git status --porcelain
if ($porcelain) {
    Write-Host '=== commit ==='
    git commit -m @"
Veri kalitesi kurallari: dosyadan SQL sorgusu

- config/queries/vk-kurallar.sql ile DQ.Rule sorgusu
- config/vk-kurallar.json yapilandirmasi
- VeriKalitesiController kurallar/sorgu API
- veri-kalitesi-kurallari sayfasi SQL sonuc tablosu
- TDUTIL baglantisi td-connections.json icinde
"@
} else {
    Write-Host 'Yeni commit yok, push deneniyor...'
}

Write-Host '=== pull --rebase ==='
git pull --rebase origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Rebase hatasi. Cozum: git status, duzenle, git add -A, git rebase --continue'
    exit 1
}

Write-Host '=== push ==='
git push -u origin main
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host ''
Write-Host 'Tamamlandi: https://github.com/KTmyanik/MerkeziFinansalVeri'
