$ErrorActionPreference = 'Stop'
Set-Location 'C:\Users\mesut\MerkeziFinansalVeri'

Write-Host '1) Log dosyasini repodan cikar...'
git rm --cached -f _push_log.txt 2>$null
git add .gitignore push-git.ps1 finish-push.ps1

$status = git status --porcelain
if ($status) {
    Write-Host '2) Yardimci commit...'
    git commit -m "Push script duzeltmesi ve log dosyasini ignore et"
}

Write-Host '3) Uzak degisiklikleri al (rebase)...'
git pull --rebase origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'Rebase cakismasi olabilir. Cozum:'
    Write-Host '  git status'
    Write-Host '  (dosyalari duzenle)'
    Write-Host '  git add -A'
    Write-Host '  git rebase --continue'
    Write-Host '  git push -u origin main'
    exit 1
}

Write-Host '4) Push...'
git push -u origin main
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host ''
Write-Host 'Tamamlandi: https://github.com/KTmyanik/MerkeziFinansalVeri'
