USE [TDUTIL];
GO

-- VIB.cfg_DataSource (veritabani-baglantisi.js DATABASES defaults)
MERGE VIB.cfg_DataSource AS tgt
USING (VALUES
    (N'TDSTG',   N'sql-stg-01.sirket.local',  N'TDSTG',   1433, N'sql'),
    (N'TDMAIN',  N'sql-main-01.sirket.local', N'TDMAIN',  1433, N'sql'),
    (N'TDREPORT', N'sql-rpt-01.sirket.local', N'TDREPORT', 1433, N'sql')
) AS src(LayerCode, ServerName, DatabaseName, Port, AuthenticationMode)
ON tgt.LayerCode = src.LayerCode
WHEN MATCHED THEN
    UPDATE SET
        ServerName = src.ServerName,
        DatabaseName = src.DatabaseName,
        Port = src.Port,
        AuthenticationMode = src.AuthenticationMode,
        UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (LayerCode, ServerName, DatabaseName, Port, AuthenticationMode)
    VALUES (src.LayerCode, src.ServerName, src.DatabaseName, src.Port, src.AuthenticationMode);
GO

-- VIB.cfg_SystemParameter — AktifMutabakatDonemId (2026-06)
DECLARE @AktifDonemId INT = (
    SELECT PeriodId FROM VIB.ops_ReconciliationPeriod WHERE YearMonth = N'2026-06'
);

IF @AktifDonemId IS NOT NULL
BEGIN
    MERGE VIB.cfg_SystemParameter AS tgt
    USING (SELECT N'AktifMutabakatDonemId' AS ParameterKey, CAST(@AktifDonemId AS NVARCHAR(500)) AS ParameterValue) AS src
    ON tgt.ParameterKey = src.ParameterKey
    WHEN MATCHED THEN
        UPDATE SET ParameterValue = src.ParameterValue, UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (ParameterKey, ParameterValue) VALUES (src.ParameterKey, src.ParameterValue);
END
GO
