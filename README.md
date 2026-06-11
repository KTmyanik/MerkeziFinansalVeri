# Merkezi Güvenilir Finansal Veri

Kurumsal finansal veri mutabakatı, süreç izleme ve raporlama platformu.

## Mimari

Proje **SQL Server veritabanı altyapısına** geçmiştir. İş verisi artık JavaScript sabitleri ve `localStorage` yerine SQL Server üzerinde tutulur; web arayüzü ASP.NET Core Web API üzerinden beslenir.

```
HTML/JS (statik sayfalar)
    └── api-client.js
            └── MerkeziFinansalVeri.Api  (ASP.NET Core 8)
                    ├── TDUTIL.VIB       (uygulama şeması)
                    └── TDSTG/TDMAIN/TDREPORT  (salt okunur DW katmanları)
```

| Katman | Konum | Açıklama |
|--------|-------|----------|
| Veritabanı şeması | `database/migrations/` | SQL CREATE scriptleri |
| Seed verileri | `database/seeds/` | Demo referans ve operasyonel veri |
| Domain | `src/MerkeziFinansalVeri.Domain/` | Entity modelleri |
| Infrastructure | `src/MerkeziFinansalVeri.Infrastructure/` | EF Core, TD bağlantıları, sync job |
| API | `src/MerkeziFinansalVeri.Api/` | REST endpoint'leri |
| Önyüz | `*.html`, `api-client.js` | Ribbon web arayüzü |

Detaylı proje özeti için [`PROJE-OZETI.md`](PROJE-OZETI.md) dosyasına bakın.

## Gereksinimler

- .NET 8.0 SDK
- SQL Server (LocalDB veya tam sürüm)
- Statik dosyalar için HTTP sunucusu (Live Server, `python -m http.server` vb.)

## Kurulum

### 1. Veritabanı

```powershell
cd database
.\setup.ps1
```

Alternatif şema (İngilizce, `TDUTIL.VIB`):

```powershell
sqlcmd -S srvdev\PASIFIK -E -i database\migrations\002_tdutil_vib_schema_en.sql
```

Ardından seed scriptlerini sırayla çalıştırın: `001_ref_seed.sql` … `005_audit_seed.sql`

### 2. API

```powershell
dotnet build MerkeziFinansalVeri.sln
dotnet run --project src/MerkeziFinansalVeri.Api
```

Swagger: `http://localhost:5038/swagger`

Connection string: `src/MerkeziFinansalVeri.Api/appsettings.json`

### 3. Web arayüzü

Statik dosyaları bir HTTP sunucusundan açın. API adresi varsayılan olarak `http://localhost:5038/api`:

```javascript
localStorage.setItem('apiBaseUrl', 'http://localhost:5038/api');
```

## WPF prototipi (eski)

`FinansalVeriApp/` altındaki WPF uygulaması bağımsız bir masaüstü prototipidir; web API ile henüz entegre değildir.

```powershell
dotnet run --project FinansalVeriApp/FinansalVeriApp.csproj
```

## Depo

GitHub: [ugurceren/MerkeziFinansalVeri](https://github.com/ugurceren/MerkeziFinansalVeri)
