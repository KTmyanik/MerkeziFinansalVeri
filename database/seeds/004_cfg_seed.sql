USE [MGTV_Uygulama];
GO

-- cfg.VeriKaynagi (veritabani-baglantisi.js DATABASES defaults)
MERGE cfg.VeriKaynagi AS tgt
USING (VALUES
    (N'TDSTG',   N'10.13.8.238',  N'TDSTG',   1433, N'windows'),
    (N'TDMAIN',  N'sql-main-01.sirket.local', N'TDMAIN',  1433, N'sql'),
    (N'TDREPORT', N'sql-rpt-01.sirket.local', N'TDREPORT', 1433, N'sql')
) AS src(KatmanKodu, Sunucu, Veritabani, Port, KimlikDogrulama)
ON tgt.KatmanKodu = src.KatmanKodu
WHEN MATCHED THEN
    UPDATE SET
        Sunucu = src.Sunucu,
        Veritabani = src.Veritabani,
        Port = src.Port,
        KimlikDogrulama = src.KimlikDogrulama,
        GuncellemeZamani = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (KatmanKodu, Sunucu, Veritabani, Port, KimlikDogrulama)
    VALUES (src.KatmanKodu, src.Sunucu, src.Veritabani, src.Port, src.KimlikDogrulama);
GO

-- cfg.SistemParametre — AktifMutabakatDonemId (2026-06)
DECLARE @AktifDonemId INT = (
    SELECT DonemId FROM ops.MutabakatDonem WHERE YilAy = N'2026-06'
);

IF @AktifDonemId IS NOT NULL
BEGIN
    MERGE cfg.SistemParametre AS tgt
    USING (SELECT N'AktifMutabakatDonemId' AS Anahtar, CAST(@AktifDonemId AS NVARCHAR(500)) AS Deger) AS src
    ON tgt.Anahtar = src.Anahtar
    WHEN MATCHED THEN
        UPDATE SET Deger = src.Deger, GuncellemeZamani = SYSUTCDATETIME()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (Anahtar, Deger) VALUES (src.Anahtar, src.Deger);
END
GO
