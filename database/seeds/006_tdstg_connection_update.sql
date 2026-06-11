-- TDSTG bağlantısını güncelle (Windows kimlik doğrulama)
USE [MGTV_Uygulama];
GO

UPDATE cfg.VeriKaynagi
SET Sunucu = N'10.13.8.238',
    Veritabani = N'TDSTG',
    Port = 1433,
    KimlikDogrulama = N'windows',
    KullaniciAdi = NULL,
    GuncellemeZamani = SYSUTCDATETIME()
WHERE KatmanKodu = N'TDSTG';
GO
