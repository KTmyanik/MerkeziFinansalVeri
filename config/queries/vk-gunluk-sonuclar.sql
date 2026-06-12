WITH RuleResultSum AS (
    SELECT
        RuleId,
        CAST(DataDate AS DATE) AS DataDate,
        FailCount,
        ErrorDescription,
        ROW_NUMBER() OVER (PARTITION BY RuleId ORDER BY StartDate DESC) AS rn
    FROM TDUTIL.DQ.RuleResult RR
    WHERE CAST(StartDate AS DATE) = CAST(GETDATE() AS DATE)
)
SELECT
    RR.DataDate,
    F.SystemName + '.' + F.SchemaName + '.' + F.DatasetName AS TableName,
    F.FieldName,
    R.ExactValue,
    RR.ErrorDescription,
    SD.QualityId,
    R.QualityLevel,
    R.RuleId,
    SD.QualityProcedureName
FROM RuleResultSum RR
    JOIN TDUTIL.DQ.[Rule] R ON RR.RuleId = R.RuleId
    JOIN TDUTIL.DQ.RelTermField RTF ON R.RelTermFieldId = RTF.RelTermFieldId
    JOIN TDUTIL.DQ.Field F ON RTF.FieldId = F.FieldId
    JOIN TDUTIL.DQ.SPRuleDefinition SD ON R.QualityId = SD.QualityId
WHERE rn = 1
    AND RR.FailCount <> 0
    AND R.[Status] = 1
ORDER BY QualityLevel ASC
