USE [TDUTIL];
GO

-- VIB.sec_Role (ROLES)
MERGE VIB.sec_Role AS tgt
USING (VALUES
    (N'admin',          N'Sistem Yöneticisi',        N'Tüm modüllere tam erişim',              N'role-admin'),
    (N'mutabakat',      N'Mutabakat Sorumlusu',      N'Portal ve mutabakat sayfaları',         N'role-mutabakat'),
    (N'rapor',          N'Raporlama Uzmanı',         N'Portal ve raporlama sayfaları',         N'role-rapor'),
    (N'surec',          N'Süreç Koordinatörü',       N'Portal ve süreç yönetimi',              N'role-surec'),
    (N'veri-kalitesi',  N'Veri Kalitesi Sorumlusu',  N'Portal ve veri kalitesi sayfaları',     N'role-veri-kalitesi'),
    (N'viewer',         N'Görüntüleyici',            N'Yalnızca portal',                       N'role-viewer')
) AS src(RoleId, Name, Description, BadgeClass)
ON tgt.RoleId = src.RoleId
WHEN MATCHED THEN
    UPDATE SET Name = src.Name, Description = src.Description, BadgeClass = src.BadgeClass
WHEN NOT MATCHED BY TARGET THEN
    INSERT (RoleId, Name, Description, BadgeClass)
    VALUES (src.RoleId, src.Name, src.Description, src.BadgeClass);
GO

-- VIB.sec_User (USERS)
MERGE VIB.sec_User AS tgt
USING (VALUES
    (9, N'Uğur Çeren',   N'ugur.ceren@sirket.com',   N'admin',          N'active',  CAST(N'2026-06-07 10:30:00' AS DATETIME2)),
    (1, N'Ahmet Yılmaz', N'ahmet.yilmaz@sirket.com', N'admin',          N'active',  CAST(N'2026-06-07 09:14:00' AS DATETIME2)),
    (2, N'Ayşe Demir',   N'ayse.demir@sirket.com',   N'mutabakat',      N'active',  CAST(N'2026-06-06 16:42:00' AS DATETIME2)),
    (3, N'Mehmet Kara',  N'mehmet.kara@sirket.com',   N'rapor',          N'active',  CAST(N'2026-06-07 08:05:00' AS DATETIME2)),
    (4, N'Zeynep Can',   N'zeynep.can@sirket.com',   N'surec',          N'active',  CAST(N'2026-06-05 11:30:00' AS DATETIME2)),
    (5, N'Seda Yıldız',  N'seda.yildiz@sirket.com',   N'veri-kalitesi',  N'active',  CAST(N'2026-06-04 14:18:00' AS DATETIME2)),
    (6, N'Fatih Şahin',  N'fatih.sahin@sirket.com',   N'mutabakat',      N'passive', CAST(N'2026-05-28 10:02:00' AS DATETIME2)),
    (7, N'Can Öztürk',   N'can.ozturk@sirket.com',    N'viewer',         N'active',  CAST(N'2026-06-07 07:22:00' AS DATETIME2)),
    (8, N'Elif Arslan',  N'elif.arslan@sirket.com',   N'veri-kalitesi',  N'active',  CAST(N'2026-06-06 13:45:00' AS DATETIME2))
) AS src(UserId, Name, Email, RoleId, Status, LastLoginAt)
ON tgt.UserId = src.UserId
WHEN MATCHED THEN
    UPDATE SET
        Name = src.Name,
        Email = src.Email,
        RoleId = src.RoleId,
        Status = src.Status,
        LastLoginAt = src.LastLoginAt,
        UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (UserId, Name, Email, RoleId, Status, LastLoginAt)
    VALUES (src.UserId, src.Name, src.Email, src.RoleId, src.Status, src.LastLoginAt);
GO

-- VIB.sec_RolePagePermission (role page permissions)
;WITH RolSayfa AS (
    SELECT RoleId, PageId FROM (VALUES
        (N'admin', N'portal'), (N'admin', N'surec'), (N'admin', N'datasetler'), (N'admin', N'task-listesi'),
        (N'admin', N'mizan'), (N'admin', N'mutabakat-donem'), (N'admin', N'fark-veren'), (N'admin', N'kebir'),
        (N'admin', N'vk-kurallar'), (N'admin', N'vk-gunluk'), (N'admin', N'veritabani-sorgu'),
        (N'admin', N'ters-bakiye'), (N'admin', N'nazim'), (N'admin', N'ayarlar'),
        (N'admin', N'kullanici-yonetimi'), (N'admin', N'kisi-yetkileri'), (N'admin', N'veritabani-baglantisi'),
        (N'mutabakat', N'portal'), (N'mutabakat', N'kebir'), (N'mutabakat', N'mizan'),
        (N'mutabakat', N'mutabakat-donem'), (N'mutabakat', N'fark-veren'),
        (N'rapor', N'portal'), (N'rapor', N'veritabani-sorgu'), (N'rapor', N'ters-bakiye'), (N'rapor', N'nazim'),
        (N'surec', N'portal'), (N'surec', N'surec'), (N'surec', N'datasetler'), (N'surec', N'task-listesi'),
        (N'veri-kalitesi', N'portal'), (N'veri-kalitesi', N'vk-kurallar'), (N'veri-kalitesi', N'vk-gunluk'),
        (N'viewer', N'portal')
    ) AS v(RoleId, PageId)
)
MERGE VIB.sec_RolePagePermission AS tgt
USING RolSayfa AS src
ON tgt.RoleId = src.RoleId AND tgt.PageId = src.PageId
WHEN NOT MATCHED BY TARGET THEN
    INSERT (RoleId, PageId) VALUES (src.RoleId, src.PageId);
GO
