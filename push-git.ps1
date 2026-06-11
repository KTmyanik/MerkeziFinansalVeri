$ErrorActionPreference = 'Continue'
Set-Location 'C:\Users\mesut\MerkeziFinansalVeri'

function Log($msg) {
    Write-Host $msg
}

Log '=== git fetch origin ==='
git fetch origin 2>&1 | ForEach-Object { Log $_ }

Log '=== git add -A ==='
git add -A 2>&1 | ForEach-Object { Log $_ }

$porcelain = git status --porcelain
if ($porcelain) {
    Log '=== git commit ==='
    git commit -m "Veritabani Sorgusu ekrani, harici config ve API uclari" 2>&1 | ForEach-Object { Log $_ }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Log 'commit atlandi (degisiklik yok)'
}

Log '=== git pull --rebase origin main ==='
git pull --rebase origin main 2>&1 | ForEach-Object { Log $_ }
if ($LASTEXITCODE -ne 0) {
    Log 'pull/rebase basarisiz. Cakisma varsa cozun: git status, duzenle, git add -A, git rebase --continue'
    exit $LASTEXITCODE
}

Log '=== git push -u origin main ==='
git push -u origin main 2>&1 | ForEach-Object { Log $_ }
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Log '=== push tamamlandi ==='
