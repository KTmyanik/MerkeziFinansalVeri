USE [TDUTIL];
GO

-- VIB.ref_Team
MERGE VIB.ref_Team AS tgt
USING (VALUES
    (N'Banka Ekip 1'),
    (N'Banka Ekip 2'),
    (N'Banka Ekip 3'),
    (N'Merkezi Kontrol')
) AS src(Name)
ON tgt.Name = src.Name AND tgt.IsDeleted = 0
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Name) VALUES (src.Name);
GO

-- VIB.ref_Page (PAGE_MENU)
MERGE VIB.ref_Page AS tgt
USING (VALUES
    (N'portal',           N'PORTAL',              N'ti-home',         N'Portal',                              N'HomePage.html',                        1),
    (N'surec',            N'SÜREÇ',               N'ti-timeline',     N'Süreç',                               N'surec.html',                           2),
    (N'datasetler',       N'SÜREÇ',               N'ti-timeline',     N'Datasetler',                          N'surec.html?view=datasetler',           3),
    (N'task-listesi',     N'SÜREÇ',               N'ti-timeline',     N'Task Listesi',                        N'surec.html?view=task-listesi',         4),
    (N'mizan',            N'MUTABAKAT',           N'ti-scale',        N'Mizan',                               N'mizan.html',                           5),
    (N'mutabakat-donem',  N'MUTABAKAT',           N'ti-scale',        N'Dönem',                               N'mutabakat.html?view=donem',            6),
    (N'fark-veren',       N'MUTABAKAT',           N'ti-scale',        N'Fark Veren Hesaplar',                 N'mutabakat.html?view=fark-veren',       7),
    (N'kebir',            N'PARAMETRE YÖNETİMİ',   N'ti-adjustments',  N'Kebir Hesapları Sorumluluk Listesi',  N'kebir-hesaplari.html',                 8),
    (N'vk-kurallar',      N'VERİ KALİTESİ',       N'ti-list-check',   N'Veri Kalitesi Kuralları',             N'veri-kalitesi-kurallari.html',         9),
    (N'vk-gunluk',        N'VERİ KALİTESİ',       N'ti-list-check',   N'Günlük Kural Sonuçları',              N'gunluk-kural-sonuclari.html',         10),
    (N'veritabani-sorgu', N'RAPORLAMA',           N'ti-chart-bar',    N'Veritabanı Sorgusu',                  N'veritabani-sorgu.html',               11),
    (N'ters-bakiye',      N'RAPORLAMA',           N'ti-chart-bar',    N'Ters Bakiye Raporu',                  NULL,                                   12),
    (N'nazim',            N'RAPORLAMA',           N'ti-chart-bar',    N'Nazım Hesapları Raporu',              NULL,                                   13),
    (N'ayarlar',          N'AYARLAR',             N'ti-settings',     N'Ayarlar',                             N'ayarlar.html',                        14),
    (N'kullanici-yonetimi', N'YÖNETİM',           N'ti-users',        N'Kullanıcı Yönetimi',                  N'kullanici-yonetimi.html',             15),
    (N'kisi-yetkileri',   N'YÖNETİM',             N'ti-users',        N'Kişi Bazlı Yetkiler',                 N'kisi-yetkileri.html',                 16),
    (N'veritabani-baglantisi', N'YÖNETİM',         N'ti-users',        N'Veritabanı Bağlantısı',               N'veritabani-baglantisi.html',          17)
) AS src(PageId, Section, SectionIcon, Label, Href, SortOrder)
ON tgt.PageId = src.PageId
WHEN MATCHED THEN
    UPDATE SET
        Section = src.Section,
        SectionIcon = src.SectionIcon,
        Label = src.Label,
        Href = src.Href,
        SortOrder = src.SortOrder
WHEN NOT MATCHED BY TARGET THEN
    INSERT (PageId, Section, SectionIcon, Label, Href, SortOrder)
    VALUES (src.PageId, src.Section, src.SectionIcon, src.Label, src.Href, src.SortOrder);
GO

-- VIB.ref_DataLayer (COCKPIT_COLUMNS)
MERGE VIB.ref_DataLayer AS tgt
USING (VALUES
    (N'TDSTG',   N'Staging — ham veri katmanı',      N'teal',   1),
    (N'TDMAIN',  N'Ana veri — kurumsal çekirdek',    N'blue',   2),
    (N'TDREPORT', N'Raporlama — analitik katman',    N'purple', 3)
) AS src(LayerCode, LayerRole, Theme, SortOrder)
ON tgt.LayerCode = src.LayerCode
WHEN MATCHED THEN
    UPDATE SET LayerRole = src.LayerRole, Theme = src.Theme, SortOrder = src.SortOrder
WHEN NOT MATCHED BY TARGET THEN
    INSERT (LayerCode, LayerRole, Theme, SortOrder)
    VALUES (src.LayerCode, src.LayerRole, src.Theme, src.SortOrder);
GO

-- VIB.ref_DataDomain (DATASET_DOMAINS)
MERGE VIB.ref_DataDomain AS tgt
USING (VALUES
    (N'fon-kullandirim', N'Fon Kullandırım', N'teal',   1),
    (N'hazine',          N'Hazine',          N'blue',   2),
    (N'mevduat',         N'Mevduat',         N'purple', 3),
    (N'masraf',          N'Masraf',          N'amber',  4),
    (N'reeskont',        N'Reeskont',        N'rose',   5)
) AS src(DomainId, Name, Theme, SortOrder)
ON tgt.DomainId = src.DomainId
WHEN MATCHED THEN
    UPDATE SET Name = src.Name, Theme = src.Theme, SortOrder = src.SortOrder
WHEN NOT MATCHED BY TARGET THEN
    INSERT (DomainId, Name, Theme, SortOrder)
    VALUES (src.DomainId, src.Name, src.Theme, src.SortOrder);
GO
