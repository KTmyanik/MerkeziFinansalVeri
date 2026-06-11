USE [TDUTIL];
GO

-- VIB.ops_ReconciliationPeriod (PERIODS)
MERGE VIB.ops_ReconciliationPeriod AS tgt
USING (VALUES
    (N'2026-06', N'Haziran 2026', N'aktif',  248, 12, NULL,           1),
    (N'2026-05', N'Mayıs 2026',   N'kapali', 246,  0, N'2026-06-03',  0),
    (N'2026-04', N'Nisan 2026',   N'kapali', 244,  0, N'2026-05-04',  0),
    (N'2026-03', N'Mart 2026',    N'onay',   241,  3, NULL,           0)
) AS src(YearMonth, Label, Status, AccountCount, VarianceCount, ClosedDate, IsActive)
ON tgt.YearMonth = src.YearMonth
WHEN MATCHED THEN
    UPDATE SET
        Label = src.Label,
        Status = src.Status,
        AccountCount = src.AccountCount,
        VarianceCount = src.VarianceCount,
        ClosedDate = src.ClosedDate,
        IsActive = src.IsActive,
        UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (YearMonth, Label, Status, AccountCount, VarianceCount, ClosedDate, IsActive)
    VALUES (src.YearMonth, src.Label, src.Status, src.AccountCount, src.VarianceCount, src.ClosedDate, src.IsActive);
GO

-- VIB.ops_CorporateAccount (kebir-hesaplari.html — 10 rows)
MERGE VIB.ops_CorporateAccount AS tgt
USING (
    SELECT
        v.AccountId,
        v.AccountName,
        e.TeamId,
        v.ExpectedAction,
        v.Source,
        v.RecordDate,
        v.UpdatedAt,
        ok.UserId AS CreatedByUserId,
        gk.UserId AS UpdatedByUserId
    FROM (VALUES
        (1,  N'Kurumsal Hesap 1',  N'Banka Ekip 1',    N'Ödeme İşlemi',      N'Banka Sistemi',   N'2024-01-15', N'2024-01-20', N'Ahmet Yılmaz', N'Mehmet Kara'),
        (2,  N'Kurumsal Hesap 2',  N'Banka Ekip 2',    N'Hesap Aktarımı',    N'Merkezi Sistem',  N'2024-01-18', N'2024-01-21', N'Ayşe Demir',   N'Zeynep Can'),
        (3,  N'Kurumsal Hesap 3',  N'Banka Ekip 1',    N'Kaydı Güncelle',    N'Banka Sistemi',   N'2024-01-20', N'2024-01-22', N'Mehmet Kara',  N'Ahmet Yılmaz'),
        (4,  N'Kurumsal Hesap 4',  N'Banka Ekip 3',    N'Doğrulama Bekle',   N'Merkezi Sistem',  N'2024-01-22', N'2024-01-23', N'Fatih Şahin',  N'Seda Yıldız'),
        (5,  N'Kurumsal Hesap 5',  N'Banka Ekip 2',    N'Bilgi Eksik',       N'Banka Sistemi',   N'2024-01-23', N'2024-01-24', N'Zeynep Can',   N'Ayşe Demir'),
        (6,  N'Kurumsal Hesap 6',  N'Banka Ekip 1',    N'İzin Bekle',        N'Merkezi Sistem',  N'2024-01-25', N'2024-01-26', N'Seda Yıldız',  N'Fatih Şahin'),
        (7,  N'Kurumsal Hesap 7',  N'Banka Ekip 3',    N'Ödeme İşlemi',      N'Banka Sistemi',   N'2024-01-26', N'2024-01-27', N'Ahmet Yılmaz', N'Mehmet Kara'),
        (8,  N'Kurumsal Hesap 8',  N'Banka Ekip 2',    N'Hesap Aktarımı',    N'Merkezi Sistem',  N'2024-01-27', N'2024-01-28', N'Zeynep Can',   N'Ayşe Demir'),
        (9,  N'Kurumsal Hesap 9',  N'Banka Ekip 1',    N'Kaydı Güncelle',    N'Banka Sistemi',   N'2024-01-28', N'2024-01-29', N'Fatih Şahin',  N'Seda Yıldız'),
        (10, N'Kurumsal Hesap 10', N'Banka Ekip 3',    N'Doğrulama Bekle',   N'Merkezi Sistem',  N'2024-01-29', N'2024-01-30', N'Mehmet Kara',  N'Ahmet Yılmaz')
    ) AS v(AccountId, AccountName, TeamName, ExpectedAction, Source, RecordDate, UpdatedAt, CreatedByName, UpdatedByName)
    INNER JOIN VIB.ref_Team e ON e.Name = v.TeamName AND e.IsDeleted = 0
    LEFT JOIN VIB.sec_User ok ON ok.Name = v.CreatedByName AND ok.IsDeleted = 0
    LEFT JOIN VIB.sec_User gk ON gk.Name = v.UpdatedByName AND gk.IsDeleted = 0
) AS src
ON tgt.AccountId = src.AccountId AND tgt.IsDeleted = 0
WHEN MATCHED THEN
    UPDATE SET
        AccountName = src.AccountName,
        TeamId = src.TeamId,
        ExpectedAction = src.ExpectedAction,
        Source = src.Source,
        RecordDate = src.RecordDate,
        UpdatedAt = src.UpdatedAt,
        CreatedByUserId = src.CreatedByUserId,
        UpdatedByUserId = src.UpdatedByUserId
WHEN NOT MATCHED BY TARGET THEN
    INSERT (AccountId, AccountName, TeamId, ExpectedAction, Source, RecordDate, UpdatedAt, CreatedByUserId, UpdatedByUserId)
    VALUES (src.AccountId, src.AccountName, src.TeamId, src.ExpectedAction, src.Source, src.RecordDate, src.UpdatedAt, src.CreatedByUserId, src.UpdatedByUserId);
GO

-- VIB.ops_VarianceAccount (DIFF_ACCOUNTS — aktif dönem 2026-06)
MERGE VIB.ops_VarianceAccount AS tgt
USING (
    SELECT
        d.PeriodId,
        v.AccountCode,
        v.AccountName,
        e.TeamId,
        v.TrialBalanceAmount,
        v.CardTableAmount,
        v.Status
    FROM (VALUES
        (N'100.01.001', N'Merkez Kasa',                    N'Banka Ekip 1',    1500000.00,  1485000.00,  N'acik'),
        (N'120.05.042', N'Ticari Alacaklar — X A.Ş.',      N'Banka Ekip 2',    2847500.00,  2851000.00,  N'inceleniyor'),
        (N'320.02.018', N'Satıcılar — Y Ltd.',             N'Banka Ekip 1',     920000.00,   915500.00,  N'acik'),
        (N'102.03.007', N'Vadesiz Mevduat — TL',           N'Merkezi Kontrol', 45800000.00, 45800000.00, N'kapatildi'),
        (N'180.01.003', N'Gelecek Aylara Ait Giderler',    N'Banka Ekip 3',     125400.00,   128900.00,  N'acik'),
        (N'391.01.002', N'Hesaplanan KDV',                 N'Banka Ekip 2',     567800.00,   562300.00,  N'inceleniyor'),
        (N'770.04.011', N'Genel Yönetim Giderleri',        N'Banka Ekip 3',     890000.00,   901200.00,  N'acik'),
        (N'257.01.001', N'Birikmiş Amortisman',            N'Merkezi Kontrol',  3200000.00,  3198500.00,  N'kapatildi')
    ) AS v(AccountCode, AccountName, TeamName, TrialBalanceAmount, CardTableAmount, Status)
    INNER JOIN VIB.ops_ReconciliationPeriod d ON d.YearMonth = N'2026-06'
    INNER JOIN VIB.ref_Team e ON e.Name = v.TeamName AND e.IsDeleted = 0
) AS src
ON tgt.PeriodId = src.PeriodId AND tgt.AccountCode = src.AccountCode AND tgt.IsDeleted = 0
WHEN MATCHED THEN
    UPDATE SET
        AccountName = src.AccountName,
        TeamId = src.TeamId,
        TrialBalanceAmount = src.TrialBalanceAmount,
        CardTableAmount = src.CardTableAmount,
        Status = src.Status,
        UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (PeriodId, AccountCode, AccountName, TeamId, TrialBalanceAmount, CardTableAmount, Status)
    VALUES (src.PeriodId, src.AccountCode, src.AccountName, src.TeamId, src.TrialBalanceAmount, src.CardTableAmount, src.Status);
GO

-- VIB.ops_ProcessDataset (COCKPIT_COLUMNS + DATASET_DOMAINS)
MERGE VIB.ops_ProcessDataset AS tgt
USING (VALUES
    (N'ds_banka_ham',       N'Banka Ham Veri',      N'TDSTG',   NULL,               1),
    (N'ds_muhasebe_raw',    N'Muhasebe Raw',        N'TDSTG',   NULL,               2),
    (N'ds_doviz_kurlari',   N'Döviz Kurları',       N'TDSTG',   NULL,               3),
    (N'ds_masraf_stg',      N'Masraf Staging',      N'TDSTG',   N'masraf',          4),
    (N'ds_kebir',           N'Kebir Defteri',       N'TDMAIN',  NULL,               5),
    (N'ds_mizan',           N'Mizan',               N'TDMAIN',  NULL,               6),
    (N'ds_yevmiye',         N'Yevmiye',             N'TDMAIN',  NULL,               7),
    (N'ds_hesap_plan',      N'Hesap Planı',         N'TDMAIN',  NULL,               8),
    (N'ds_bilanco',         N'Bilanço',             N'TDREPORT', NULL,              9),
    (N'ds_gelir',           N'Gelir Tablosu',       N'TDREPORT', NULL,             10),
    (N'ds_ters_bakiye',     N'Ters Bakiye',         N'TDREPORT', NULL,             11),
    (N'ds_nazim',           N'Nazım Hesapları',     N'TDREPORT', NULL,             12),
    (N'ds_fon_hareket',      N'Fon Hareket',         NULL,       N'fon-kullandirim', 13),
    (N'ds_fon_limit',        N'Fon Limit',           NULL,       N'fon-kullandirim', 14),
    (N'ds_fon_faiz',         N'Fon Faiz',            NULL,       N'fon-kullandirim', 15),
    (N'ds_fon_izleme',       N'Fon İzleme',          NULL,       N'fon-kullandirim', 16),
    (N'ds_hazine_portfoy',   N'Hazine Portföy',      NULL,       N'hazine',          17),
    (N'ds_hazine_islem',     N'Hazine İşlem',        NULL,       N'hazine',          18),
    (N'ds_hazine_deger',     N'Hazine Değerleme',    NULL,       N'hazine',          19),
    (N'ds_hazine_risk',      N'Hazine Risk',         NULL,       N'hazine',          20),
    (N'ds_hazine_mutabakat', N'Hazine Mutabakat',    NULL,       N'hazine',          21),
    (N'ds_mevduat_vadeli',   N'Vadeli Mevduat',      NULL,       N'mevduat',         22),
    (N'ds_mevduat_vadesiz',  N'Vadesiz Mevduat',     NULL,       N'mevduat',         23),
    (N'ds_mevduat_faiz',     N'Mevduat Faiz',        NULL,       N'mevduat',         24),
    (N'ds_mevduat_musteri',  N'Mevduat Müşteri',     NULL,       N'mevduat',         25),
    (N'ds_mevduat_hareket',  N'Mevduat Hareket',     NULL,       N'mevduat',         26),
    (N'ds_mevduat_rapor',    N'Mevduat Rapor',       NULL,       N'mevduat',         27),
    (N'ds_masraf_hesap',     N'Masraf Hesap',        NULL,       N'masraf',          28),
    (N'ds_masraf_dagitim',   N'Masraf Dağıtım',      NULL,       N'masraf',          29),
    (N'ds_masraf_butce',     N'Masraf Bütçe',        NULL,       N'masraf',          30),
    (N'ds_reeskont_portfoy', N'Reeskont Portföy',    NULL,       N'reeskont',        31),
    (N'ds_reeskont_faiz',    N'Reeskont Faiz',       NULL,       N'reeskont',        32),
    (N'ds_reeskont_vade',    N'Reeskont Vade',       NULL,       N'reeskont',        33)
) AS src(Code, Label, LayerCode, DomainId, SortOrder)
ON tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET
        Label = src.Label,
        LayerCode = src.LayerCode,
        DomainId = src.DomainId,
        SortOrder = src.SortOrder
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Code, Label, LayerCode, DomainId, SortOrder)
    VALUES (src.Code, src.Label, src.LayerCode, src.DomainId, src.SortOrder);
GO

-- VIB.ops_ProcessTaskDefinition (COCKPIT_COLUMNS tasks)
MERGE VIB.ops_ProcessTaskDefinition AS tgt
USING (
    SELECT ds.DatasetId, v.Label, v.SortOrder
    FROM (VALUES
        (N'ds_banka_ham',     N'Yükleme',       1),
        (N'ds_banka_ham',     N'Validasyon',    2),
        (N'ds_banka_ham',     N'Staging Onay',  3),
        (N'ds_muhasebe_raw',  N'Yükleme',       1),
        (N'ds_muhasebe_raw',  N'Validasyon',    2),
        (N'ds_muhasebe_raw',  N'Staging Onay',  3),
        (N'ds_doviz_kurlari', N'Yükleme',      1),
        (N'ds_doviz_kurlari', N'Validasyon',    2),
        (N'ds_doviz_kurlari', N'Staging Onay',  3),
        (N'ds_masraf_stg',    N'Yükleme',       1),
        (N'ds_masraf_stg',    N'Validasyon',    2),
        (N'ds_masraf_stg',    N'Staging Onay',  3),
        (N'ds_kebir',         N'Dönüşüm',       1),
        (N'ds_kebir',         N'Mutabakat',     2),
        (N'ds_kebir',         N'Ana Veri Onay', 3),
        (N'ds_mizan',         N'Dönüşüm',       1),
        (N'ds_mizan',         N'Mutabakat',     2),
        (N'ds_mizan',         N'Ana Veri Onay', 3),
        (N'ds_yevmiye',       N'Dönüşüm',       1),
        (N'ds_yevmiye',       N'Mutabakat',     2),
        (N'ds_yevmiye',       N'Ana Veri Onay', 3),
        (N'ds_hesap_plan',    N'Dönüşüm',       1),
        (N'ds_hesap_plan',    N'Mutabakat',     2),
        (N'ds_hesap_plan',    N'Ana Veri Onay', 3),
        (N'ds_bilanco',       N'Agregasyon',    1),
        (N'ds_bilanco',       N'Rapor Üretim',  2),
        (N'ds_bilanco',       N'Yayınlama',     3),
        (N'ds_gelir',         N'Agregasyon',    1),
        (N'ds_gelir',         N'Rapor Üretim',  2),
        (N'ds_gelir',         N'Yayınlama',     3),
        (N'ds_ters_bakiye',   N'Agregasyon',    1),
        (N'ds_ters_bakiye',   N'Rapor Üretim',  2),
        (N'ds_ters_bakiye',   N'Yayınlama',     3),
        (N'ds_nazim',         N'Agregasyon',    1),
        (N'ds_nazim',         N'Rapor Üretim',  2),
        (N'ds_nazim',         N'Yayınlama',     3)
    ) AS v(DatasetCode, Label, SortOrder)
    INNER JOIN VIB.ops_ProcessDataset ds ON ds.Code = v.DatasetCode
) AS src
ON tgt.DatasetId = src.DatasetId AND tgt.Label = src.Label
WHEN MATCHED THEN
    UPDATE SET SortOrder = src.SortOrder
WHEN NOT MATCHED BY TARGET THEN
    INSERT (DatasetId, Label, SortOrder)
    VALUES (src.DatasetId, src.Label, src.SortOrder);
GO

-- VIB.ops_ProcessTaskStatus (COCKPIT_COLUMNS task statuses — aktif dönem)
MERGE VIB.ops_ProcessTaskStatus AS tgt
USING (
    SELECT
        gt.TaskDefinitionId,
        d.PeriodId,
        v.Status
    FROM (VALUES
        (N'ds_banka_ham',     N'Yükleme',       N'done'),
        (N'ds_banka_ham',     N'Validasyon',    N'done'),
        (N'ds_banka_ham',     N'Staging Onay',  N'done'),
        (N'ds_muhasebe_raw',  N'Yükleme',       N'done'),
        (N'ds_muhasebe_raw',  N'Validasyon',    N'running'),
        (N'ds_muhasebe_raw',  N'Staging Onay',  N'pending'),
        (N'ds_doviz_kurlari', N'Yükleme',       N'done'),
        (N'ds_doviz_kurlari', N'Validasyon',    N'done'),
        (N'ds_doviz_kurlari', N'Staging Onay',  N'done'),
        (N'ds_masraf_stg',    N'Yükleme',       N'running'),
        (N'ds_masraf_stg',    N'Validasyon',    N'pending'),
        (N'ds_masraf_stg',    N'Staging Onay',  N'pending'),
        (N'ds_kebir',         N'Dönüşüm',       N'done'),
        (N'ds_kebir',         N'Mutabakat',     N'running'),
        (N'ds_kebir',         N'Ana Veri Onay', N'pending'),
        (N'ds_mizan',         N'Dönüşüm',       N'done'),
        (N'ds_mizan',         N'Mutabakat',     N'running'),
        (N'ds_mizan',         N'Ana Veri Onay', N'pending'),
        (N'ds_yevmiye',       N'Dönüşüm',       N'done'),
        (N'ds_yevmiye',       N'Mutabakat',     N'pending'),
        (N'ds_yevmiye',       N'Ana Veri Onay', N'pending'),
        (N'ds_hesap_plan',    N'Dönüşüm',       N'done'),
        (N'ds_hesap_plan',    N'Mutabakat',     N'done'),
        (N'ds_hesap_plan',    N'Ana Veri Onay', N'done'),
        (N'ds_bilanco',       N'Agregasyon',    N'pending'),
        (N'ds_bilanco',       N'Rapor Üretim',  N'pending'),
        (N'ds_bilanco',       N'Yayınlama',     N'pending'),
        (N'ds_gelir',         N'Agregasyon',    N'pending'),
        (N'ds_gelir',         N'Rapor Üretim',  N'pending'),
        (N'ds_gelir',         N'Yayınlama',     N'pending'),
        (N'ds_ters_bakiye',   N'Agregasyon',    N'pending'),
        (N'ds_ters_bakiye',   N'Rapor Üretim',  N'pending'),
        (N'ds_ters_bakiye',   N'Yayınlama',     N'pending'),
        (N'ds_nazim',         N'Agregasyon',    N'pending'),
        (N'ds_nazim',         N'Rapor Üretim',  N'pending'),
        (N'ds_nazim',         N'Yayınlama',     N'pending')
    ) AS v(DatasetCode, TaskLabel, Status)
    INNER JOIN VIB.ops_ProcessDataset ds ON ds.Code = v.DatasetCode
    INNER JOIN VIB.ops_ProcessTaskDefinition gt ON gt.DatasetId = ds.DatasetId AND gt.Label = v.TaskLabel
    INNER JOIN VIB.ops_ReconciliationPeriod d ON d.YearMonth = N'2026-06'
) AS src
ON tgt.TaskDefinitionId = src.TaskDefinitionId AND ISNULL(tgt.PeriodId, -1) = ISNULL(src.PeriodId, -1)
WHEN MATCHED THEN
    UPDATE SET Status = src.Status, LastUpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TaskDefinitionId, PeriodId, Status)
    VALUES (src.TaskDefinitionId, src.PeriodId, src.Status);
GO

-- VIB.ops_DataQualityRule (RULES)
MERGE VIB.ops_DataQualityRule AS tgt
USING (VALUES
    (N'DQ-001', N'Bakiye işareti kontrolü',       N'Mutabakat', N'Kritik', N'Aktif'),
    (N'DQ-002', N'Hesap kodu formatı',             N'Parametre', N'Yüksek', N'Aktif'),
    (N'DQ-003', N'Boş alan kontrolü — IBAN',      N'Hazine',    N'Orta',   N'Aktif'),
    (N'DQ-004', N'Tarih aralığı tutarlılığı',      N'Süreç',     N'Yüksek', N'Aktif'),
    (N'DQ-005', N'Duplicate kayıt tespiti',        N'Mevduat',   N'Kritik', N'Pasif'),
    (N'DQ-006', N'Referans tablo eşleşmesi',       N'Masraf',    N'Orta',   N'Aktif')
) AS src(RuleId, Name, Domain, Severity, Status)
ON tgt.RuleId = src.RuleId
WHEN MATCHED THEN
    UPDATE SET Name = src.Name, Domain = src.Domain, Severity = src.Severity, Status = src.Status, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (RuleId, Name, Domain, Severity, Status)
    VALUES (src.RuleId, src.Name, src.Domain, src.Severity, src.Status);
GO

-- VIB.ops_DataQualityRuleResult (DAILY_RESULTS)
MERGE VIB.ops_DataQualityRuleResult AS tgt
USING (VALUES
    (CAST(N'2026-06-07' AS DATE), N'DQ-001', 248, 3, N'warn'),
    (CAST(N'2026-06-07' AS DATE), N'DQ-002', 512, 0, N'ok'),
    (CAST(N'2026-06-07' AS DATE), N'DQ-003',  89, 7, N'fail'),
    (CAST(N'2026-06-07' AS DATE), N'DQ-004', 156, 1, N'warn'),
    (CAST(N'2026-06-06' AS DATE), N'DQ-001', 247, 4, N'warn'),
    (CAST(N'2026-06-06' AS DATE), N'DQ-006', 320, 0, N'ok')
) AS src(ExecutionDate, RuleId, PassedCount, FailedCount, Result)
ON tgt.ExecutionDate = src.ExecutionDate AND tgt.RuleId = src.RuleId
WHEN MATCHED THEN
    UPDATE SET PassedCount = src.PassedCount, FailedCount = src.FailedCount, Result = src.Result
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ExecutionDate, RuleId, PassedCount, FailedCount, Result)
    VALUES (src.ExecutionDate, src.RuleId, src.PassedCount, src.FailedCount, src.Result);
GO

-- VIB.ops_ReportDefinition (placeholder raporlar)
MERGE VIB.ops_ReportDefinition AS tgt
USING (VALUES
    (N'ters-bakiye', N'Ters Bakiye Raporu',       N'TDREPORT', N'vw_TersBakiye',    NULL),
    (N'nazim',       N'Nazım Hesapları Raporu',   N'TDREPORT', N'vw_NazimHesaplari', NULL)
) AS src(ReportCode, Name, SourceLayer, ViewName, StoredProcedureName)
ON tgt.ReportCode = src.ReportCode
WHEN MATCHED THEN
    UPDATE SET Name = src.Name, SourceLayer = src.SourceLayer, ViewName = src.ViewName, StoredProcedureName = src.StoredProcedureName
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ReportCode, Name, SourceLayer, ViewName, StoredProcedureName)
    VALUES (src.ReportCode, src.Name, src.SourceLayer, src.ViewName, src.StoredProcedureName);
GO
