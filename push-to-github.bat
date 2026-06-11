@echo off
setlocal
cd /d "%~dp0"

set REPO=origin

echo === Git durumu ===
git status
echo.

echo === Degisiklikler ekleniyor ===
git add -A
git status
echo.

git diff --cached --quiet
if %ERRORLEVEL%==0 (
    echo Commit edilecek degisiklik yok, dogrudan push deneniyor...
) else (
    echo === Commit ===
    git commit -m "Veritabani Sorgusu ekrani, harici config ve API uclari"
    if errorlevel 1 exit /b 1
)

echo.
echo === Push: %REPO% (main) ===
git push -u %REPO% main
if errorlevel 1 (
    echo.
    echo Push basarisiz. Olasi nedenler:
    echo - GitHub hesabinizda KTmyanik reposuna yazma yetkisi yok
    echo - Yanlis hesapla oturum acik ^(403^)
    echo.
    echo Cozum: Git Credential Manager ile KTmyanik hesabina giris yapin
    echo   gh auth login
    echo veya
    echo   git credential-manager github login
    exit /b 1
)

echo.
echo Tamamlandi.
pause
