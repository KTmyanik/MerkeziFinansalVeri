USE [TDUTIL];
GO

-- VIB.audit_ActivityLog (HomePage.html portal — Son Aktiviteler)
IF NOT EXISTS (SELECT 1 FROM VIB.audit_ActivityLog WHERE EventType = N'edit' AND Title = N'Kurumsal Hesap 3 güncellendi')
    INSERT INTO VIB.audit_ActivityLog (EventType, Title, Detail, UserId, CreatedAt)
    VALUES (N'edit', N'Kurumsal Hesap 3 güncellendi', N'Mehmet Kara — Sorumlu ekip değişikliği', 3, CAST(N'2026-06-07 10:18:00' AS DATETIME2));
GO

IF NOT EXISTS (SELECT 1 FROM VIB.audit_ActivityLog WHERE EventType = N'alert' AND Title = N'7 hesapta aksiyon bekleniyor')
    INSERT INTO VIB.audit_ActivityLog (EventType, Title, Detail, UserId, CreatedAt)
    VALUES (N'alert', N'7 hesapta aksiyon bekleniyor', N'Banka Ekip 2 — Doğrulama süreci', NULL, CAST(N'2026-06-07 09:30:00' AS DATETIME2));
GO

IF NOT EXISTS (SELECT 1 FROM VIB.audit_ActivityLog WHERE EventType = N'ok' AND Title = N'Ocak mutabakatı onaylandı')
    INSERT INTO VIB.audit_ActivityLog (EventType, Title, Detail, UserId, CreatedAt)
    VALUES (N'ok', N'Ocak mutabakatı onaylandı', N'Merkezi Kontrol — Mizan eşleşmesi tamam', NULL, CAST(N'2026-06-07 07:30:00' AS DATETIME2));
GO

IF NOT EXISTS (SELECT 1 FROM VIB.audit_ActivityLog WHERE EventType = N'export' AND Title = N'Excel dışa aktarım tamamlandı')
    INSERT INTO VIB.audit_ActivityLog (EventType, Title, Detail, UserId, CreatedAt)
    VALUES (N'export', N'Excel dışa aktarım tamamlandı', N'Ayşe Demir — Gelir tablosu raporu', 2, CAST(N'2026-06-06 16:42:00' AS DATETIME2));
GO
