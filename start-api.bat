@echo off
title Merkezi Finansal Veri - API
cd /d "%~dp0"
echo API baslatiliyor: http://localhost:5038
echo Swagger: http://localhost:5038/swagger
echo.
echo HTML sayfalarini file:// ile degil, bir HTTP sunucusundan acin.
echo Ornek: npx --yes serve -l 5500
echo        localStorage.setItem('apiBaseUrl','http://localhost:5038/api')
echo.
dotnet run --project "src\MerkeziFinansalVeri.Api\MerkeziFinansalVeri.Api.csproj"
pause
