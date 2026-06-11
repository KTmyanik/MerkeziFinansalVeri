/*
    MGTV Application — initial schema (English identifiers)
    Single schema: VIB
    Table naming: {logical_schema}_{TableName}  e.g. VIB.cfg_DataSource
    Database: TDUTIL
    Recommended collation: Turkish_CI_AS
*/

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'TDUTIL')
BEGIN
    CREATE DATABASE [TDUTIL];
END
GO

USE [TDUTIL];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'VIB')
    EXEC('CREATE SCHEMA VIB');
GO

/* =============================================================================
   REFERENCE  (logical schema: ref)
   ============================================================================= */

IF OBJECT_ID(N'VIB.ref_Team', N'U') IS NULL
CREATE TABLE VIB.ref_Team (
    TeamId          INT             IDENTITY(1,1) NOT NULL,
    Name            NVARCHAR(100)   NOT NULL,
    IsActive        BIT             NOT NULL CONSTRAINT DF_ref_Team_IsActive DEFAULT (1),
    CreatedAt       DATETIME2       NOT NULL CONSTRAINT DF_ref_Team_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt       DATETIME2       NULL,
    IsDeleted       BIT             NOT NULL CONSTRAINT DF_ref_Team_IsDeleted DEFAULT (0),
    CONSTRAINT PK_ref_Team PRIMARY KEY (TeamId)
);
GO

IF OBJECT_ID(N'VIB.ref_Page', N'U') IS NULL
CREATE TABLE VIB.ref_Page (
    PageId          NVARCHAR(50)    NOT NULL,
    Section         NVARCHAR(100)   NOT NULL,
    SectionIcon     NVARCHAR(50)    NULL,
    Label           NVARCHAR(200)   NOT NULL,
    Href            NVARCHAR(500)   NULL,
    SortOrder       INT             NOT NULL CONSTRAINT DF_ref_Page_SortOrder DEFAULT (0),
    CONSTRAINT PK_ref_Page PRIMARY KEY (PageId)
);
GO

IF OBJECT_ID(N'VIB.ref_DataLayer', N'U') IS NULL
CREATE TABLE VIB.ref_DataLayer (
    LayerCode       NVARCHAR(20)    NOT NULL,
    LayerRole       NVARCHAR(200)   NOT NULL,
    Theme           NVARCHAR(20)    NOT NULL,
    SortOrder       INT             NOT NULL CONSTRAINT DF_ref_DataLayer_SortOrder DEFAULT (0),
    CONSTRAINT PK_ref_DataLayer PRIMARY KEY (LayerCode)
);
GO

IF OBJECT_ID(N'VIB.ref_DataDomain', N'U') IS NULL
CREATE TABLE VIB.ref_DataDomain (
    DomainId        NVARCHAR(50)    NOT NULL,
    Name            NVARCHAR(100)   NOT NULL,
    Theme           NVARCHAR(20)    NOT NULL,
    SortOrder       INT             NOT NULL CONSTRAINT DF_ref_DataDomain_SortOrder DEFAULT (0),
    CONSTRAINT PK_ref_DataDomain PRIMARY KEY (DomainId)
);
GO

/* =============================================================================
   SECURITY  (logical schema: sec)
   ============================================================================= */

IF OBJECT_ID(N'VIB.sec_Role', N'U') IS NULL
CREATE TABLE VIB.sec_Role (
    RoleId          NVARCHAR(50)    NOT NULL,
    Name            NVARCHAR(100)   NOT NULL,
    Description     NVARCHAR(500)   NULL,
    BadgeClass      NVARCHAR(50)    NULL,
    CONSTRAINT PK_sec_Role PRIMARY KEY (RoleId)
);
GO

IF OBJECT_ID(N'VIB.sec_User', N'U') IS NULL
CREATE TABLE VIB.sec_User (
    UserId          INT             NOT NULL,
    Name            NVARCHAR(200)   NOT NULL,
    Email           NVARCHAR(200)   NOT NULL,
    RoleId          NVARCHAR(50)    NOT NULL,
    Status          NVARCHAR(20)    NOT NULL CONSTRAINT DF_sec_User_Status DEFAULT (N'active'),
    LastLoginAt     DATETIME2       NULL,
    CreatedAt       DATETIME2       NOT NULL CONSTRAINT DF_sec_User_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt       DATETIME2       NULL,
    IsDeleted       BIT             NOT NULL CONSTRAINT DF_sec_User_IsDeleted DEFAULT (0),
    CONSTRAINT PK_sec_User PRIMARY KEY (UserId),
    CONSTRAINT FK_sec_User_Role FOREIGN KEY (RoleId) REFERENCES VIB.sec_Role (RoleId)
);
GO

IF OBJECT_ID(N'VIB.sec_RolePagePermission', N'U') IS NULL
CREATE TABLE VIB.sec_RolePagePermission (
    RoleId          NVARCHAR(50)    NOT NULL,
    PageId          NVARCHAR(50)    NOT NULL,
    CONSTRAINT PK_sec_RolePagePermission PRIMARY KEY (RoleId, PageId),
    CONSTRAINT FK_sec_RolePagePermission_Role FOREIGN KEY (RoleId) REFERENCES VIB.sec_Role (RoleId),
    CONSTRAINT FK_sec_RolePagePermission_Page FOREIGN KEY (PageId) REFERENCES VIB.ref_Page (PageId)
);
GO

IF OBJECT_ID(N'VIB.sec_UserPagePermission', N'U') IS NULL
CREATE TABLE VIB.sec_UserPagePermission (
    UserId          INT             NOT NULL,
    PageId          NVARCHAR(50)    NOT NULL,
    IsGranted       BIT             NOT NULL CONSTRAINT DF_sec_UserPagePermission_IsGranted DEFAULT (1),
    CONSTRAINT PK_sec_UserPagePermission PRIMARY KEY (UserId, PageId),
    CONSTRAINT FK_sec_UserPagePermission_User FOREIGN KEY (UserId) REFERENCES VIB.sec_User (UserId),
    CONSTRAINT FK_sec_UserPagePermission_Page FOREIGN KEY (PageId) REFERENCES VIB.ref_Page (PageId)
);
GO

/* =============================================================================
   CONFIGURATION  (logical schema: cfg)
   ============================================================================= */

IF OBJECT_ID(N'VIB.cfg_DataSource', N'U') IS NULL
CREATE TABLE VIB.cfg_DataSource (
    SourceId            INT             IDENTITY(1,1) NOT NULL,
    LayerCode           NVARCHAR(20)    NOT NULL,
    ServerName          NVARCHAR(200)   NOT NULL,
    DatabaseName        NVARCHAR(100)   NOT NULL,
    Port                INT             NOT NULL CONSTRAINT DF_cfg_DataSource_Port DEFAULT (1433),
    AuthenticationMode  NVARCHAR(20)    NOT NULL CONSTRAINT DF_cfg_DataSource_AuthMode DEFAULT (N'sql'),
    Username            NVARCHAR(100)   NULL,
    IsPasswordStored    BIT             NOT NULL CONSTRAINT DF_cfg_DataSource_IsPasswordStored DEFAULT (0),
    Status              NVARCHAR(20)    NOT NULL CONSTRAINT DF_cfg_DataSource_Status DEFAULT (N'unknown'),
    UpdatedAt           DATETIME2       NOT NULL CONSTRAINT DF_cfg_DataSource_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_cfg_DataSource PRIMARY KEY (SourceId),
    CONSTRAINT FK_cfg_DataSource_DataLayer FOREIGN KEY (LayerCode) REFERENCES VIB.ref_DataLayer (LayerCode)
);
GO

IF OBJECT_ID(N'VIB.cfg_SystemParameter', N'U') IS NULL
CREATE TABLE VIB.cfg_SystemParameter (
    ParameterKey    NVARCHAR(100)   NOT NULL,
    ParameterValue  NVARCHAR(500)   NOT NULL,
    UpdatedAt       DATETIME2       NOT NULL CONSTRAINT DF_cfg_SystemParameter_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_cfg_SystemParameter PRIMARY KEY (ParameterKey)
);
GO

/* =============================================================================
   OPERATIONS  (logical schema: ops)
   ============================================================================= */

IF OBJECT_ID(N'VIB.ops_CorporateAccount', N'U') IS NULL
CREATE TABLE VIB.ops_CorporateAccount (
    AccountNo           INT             IDENTITY(1,1) NOT NULL,
    AccountId           INT             NOT NULL,
    AccountName         NVARCHAR(200)   NOT NULL,
    TeamId              INT             NOT NULL,
    ExpectedAction      NVARCHAR(100)   NULL,
    Source              NVARCHAR(50)    NULL,
    RecordDate          DATE            NOT NULL,
    UpdatedAt           DATETIME2       NOT NULL,
    CreatedByUserId     INT             NULL,
    UpdatedByUserId     INT             NULL,
    CreatedAt           DATETIME2       NOT NULL CONSTRAINT DF_ops_CorporateAccount_CreatedAt DEFAULT (SYSUTCDATETIME()),
    IsDeleted           BIT             NOT NULL CONSTRAINT DF_ops_CorporateAccount_IsDeleted DEFAULT (0),
    CONSTRAINT PK_ops_CorporateAccount PRIMARY KEY (AccountNo),
    CONSTRAINT UQ_ops_CorporateAccount_AccountId UNIQUE (AccountId),
    CONSTRAINT FK_ops_CorporateAccount_Team FOREIGN KEY (TeamId) REFERENCES VIB.ref_Team (TeamId),
    CONSTRAINT FK_ops_CorporateAccount_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES VIB.sec_User (UserId),
    CONSTRAINT FK_ops_CorporateAccount_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES VIB.sec_User (UserId)
);
GO

IF OBJECT_ID(N'VIB.ops_ReconciliationPeriod', N'U') IS NULL
CREATE TABLE VIB.ops_ReconciliationPeriod (
    PeriodId            INT             IDENTITY(1,1) NOT NULL,
    YearMonth           CHAR(7)         NOT NULL,
    Label               NVARCHAR(100)   NOT NULL,
    Status              NVARCHAR(20)    NOT NULL,
    AccountCount        INT             NOT NULL CONSTRAINT DF_ops_ReconciliationPeriod_AccountCount DEFAULT (0),
    VarianceCount       INT             NOT NULL CONSTRAINT DF_ops_ReconciliationPeriod_VarianceCount DEFAULT (0),
    ClosedDate          DATE            NULL,
    IsActive            BIT             NOT NULL CONSTRAINT DF_ops_ReconciliationPeriod_IsActive DEFAULT (0),
    CreatedAt           DATETIME2       NOT NULL CONSTRAINT DF_ops_ReconciliationPeriod_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt           DATETIME2       NULL,
    CONSTRAINT PK_ops_ReconciliationPeriod PRIMARY KEY (PeriodId),
    CONSTRAINT UQ_ops_ReconciliationPeriod_YearMonth UNIQUE (YearMonth)
);
GO

IF OBJECT_ID(N'VIB.ops_VarianceAccount', N'U') IS NULL
CREATE TABLE VIB.ops_VarianceAccount (
    VarianceId              INT             IDENTITY(1,1) NOT NULL,
    PeriodId                INT             NOT NULL,
    AccountCode             NVARCHAR(50)    NOT NULL,
    AccountName             NVARCHAR(200)   NOT NULL,
    TeamId                  INT             NOT NULL,
    TrialBalanceAmount      DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ops_VarianceAccount_TrialBalance DEFAULT (0),
    CardTableAmount         DECIMAL(18,2)   NOT NULL CONSTRAINT DF_ops_VarianceAccount_CardTable DEFAULT (0),
    VarianceAmount          AS (TrialBalanceAmount - CardTableAmount) PERSISTED,
    Status                  NVARCHAR(20)    NOT NULL CONSTRAINT DF_ops_VarianceAccount_Status DEFAULT (N'open'),
    CreatedAt               DATETIME2       NOT NULL CONSTRAINT DF_ops_VarianceAccount_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt               DATETIME2       NULL,
    IsDeleted               BIT             NOT NULL CONSTRAINT DF_ops_VarianceAccount_IsDeleted DEFAULT (0),
    CONSTRAINT PK_ops_VarianceAccount PRIMARY KEY (VarianceId),
    CONSTRAINT UQ_ops_VarianceAccount_PeriodAccount UNIQUE (PeriodId, AccountCode),
    CONSTRAINT FK_ops_VarianceAccount_Period FOREIGN KEY (PeriodId) REFERENCES VIB.ops_ReconciliationPeriod (PeriodId),
    CONSTRAINT FK_ops_VarianceAccount_Team FOREIGN KEY (TeamId) REFERENCES VIB.ref_Team (TeamId)
);
GO

IF OBJECT_ID(N'VIB.ops_ProcessDataset', N'U') IS NULL
CREATE TABLE VIB.ops_ProcessDataset (
    DatasetId       INT             IDENTITY(1,1) NOT NULL,
    Code            NVARCHAR(50)    NOT NULL,
    Label           NVARCHAR(200)   NOT NULL,
    LayerCode       NVARCHAR(20)    NULL,
    DomainId        NVARCHAR(50)    NULL,
    SortOrder       INT             NOT NULL CONSTRAINT DF_ops_ProcessDataset_SortOrder DEFAULT (0),
    CONSTRAINT PK_ops_ProcessDataset PRIMARY KEY (DatasetId),
    CONSTRAINT UQ_ops_ProcessDataset_Code UNIQUE (Code),
    CONSTRAINT FK_ops_ProcessDataset_DataLayer FOREIGN KEY (LayerCode) REFERENCES VIB.ref_DataLayer (LayerCode),
    CONSTRAINT FK_ops_ProcessDataset_DataDomain FOREIGN KEY (DomainId) REFERENCES VIB.ref_DataDomain (DomainId)
);
GO

IF OBJECT_ID(N'VIB.ops_ProcessTaskDefinition', N'U') IS NULL
CREATE TABLE VIB.ops_ProcessTaskDefinition (
    TaskDefinitionId    INT             IDENTITY(1,1) NOT NULL,
    DatasetId           INT             NOT NULL,
    Label               NVARCHAR(100)   NOT NULL,
    SortOrder           INT             NOT NULL CONSTRAINT DF_ops_ProcessTaskDefinition_SortOrder DEFAULT (0),
    CONSTRAINT PK_ops_ProcessTaskDefinition PRIMARY KEY (TaskDefinitionId),
    CONSTRAINT FK_ops_ProcessTaskDefinition_Dataset FOREIGN KEY (DatasetId) REFERENCES VIB.ops_ProcessDataset (DatasetId)
);
GO

IF OBJECT_ID(N'VIB.ops_ProcessTaskStatus', N'U') IS NULL
CREATE TABLE VIB.ops_ProcessTaskStatus (
    TaskStatusId        INT             IDENTITY(1,1) NOT NULL,
    TaskDefinitionId    INT             NOT NULL,
    PeriodId            INT             NULL,
    Status              NVARCHAR(20)    NOT NULL CONSTRAINT DF_ops_ProcessTaskStatus_Status DEFAULT (N'pending'),
    LastUpdatedAt       DATETIME2       NOT NULL CONSTRAINT DF_ops_ProcessTaskStatus_LastUpdatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_ops_ProcessTaskStatus PRIMARY KEY (TaskStatusId),
    CONSTRAINT UQ_ops_ProcessTaskStatus_TaskPeriod UNIQUE (TaskDefinitionId, PeriodId),
    CONSTRAINT FK_ops_ProcessTaskStatus_TaskDefinition FOREIGN KEY (TaskDefinitionId) REFERENCES VIB.ops_ProcessTaskDefinition (TaskDefinitionId),
    CONSTRAINT FK_ops_ProcessTaskStatus_Period FOREIGN KEY (PeriodId) REFERENCES VIB.ops_ReconciliationPeriod (PeriodId)
);
GO

IF OBJECT_ID(N'VIB.ops_ProcessTaskRestartLog', N'U') IS NULL
CREATE TABLE VIB.ops_ProcessTaskRestartLog (
    LogId               INT             IDENTITY(1,1) NOT NULL,
    TaskDefinitionId    INT             NOT NULL,
    UserId              INT             NULL,
    CreatedAt           DATETIME2       NOT NULL CONSTRAINT DF_ops_ProcessTaskRestartLog_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_ops_ProcessTaskRestartLog PRIMARY KEY (LogId),
    CONSTRAINT FK_ops_ProcessTaskRestartLog_TaskDefinition FOREIGN KEY (TaskDefinitionId) REFERENCES VIB.ops_ProcessTaskDefinition (TaskDefinitionId),
    CONSTRAINT FK_ops_ProcessTaskRestartLog_User FOREIGN KEY (UserId) REFERENCES VIB.sec_User (UserId)
);
GO

IF OBJECT_ID(N'VIB.ops_DataQualityRule', N'U') IS NULL
CREATE TABLE VIB.ops_DataQualityRule (
    RuleId          NVARCHAR(20)    NOT NULL,
    Name            NVARCHAR(200)   NOT NULL,
    Domain          NVARCHAR(100)   NOT NULL,
    Severity        NVARCHAR(20)    NOT NULL,
    Status          NVARCHAR(20)    NOT NULL CONSTRAINT DF_ops_DataQualityRule_Status DEFAULT (N'Active'),
    SqlExpression   NVARCHAR(MAX)   NULL,
    CreatedAt       DATETIME2       NOT NULL CONSTRAINT DF_ops_DataQualityRule_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt       DATETIME2       NULL,
    CONSTRAINT PK_ops_DataQualityRule PRIMARY KEY (RuleId)
);
GO

IF OBJECT_ID(N'VIB.ops_DataQualityRuleResult', N'U') IS NULL
CREATE TABLE VIB.ops_DataQualityRuleResult (
    ResultId        INT             IDENTITY(1,1) NOT NULL,
    ExecutionDate   DATE            NOT NULL,
    RuleId          NVARCHAR(20)    NOT NULL,
    PassedCount     INT             NOT NULL CONSTRAINT DF_ops_DataQualityRuleResult_PassedCount DEFAULT (0),
    FailedCount     INT             NOT NULL CONSTRAINT DF_ops_DataQualityRuleResult_FailedCount DEFAULT (0),
    Result          NVARCHAR(20)    NOT NULL,
    DetailJson      NVARCHAR(MAX)   NULL,
    CONSTRAINT PK_ops_DataQualityRuleResult PRIMARY KEY (ResultId),
    CONSTRAINT FK_ops_DataQualityRuleResult_Rule FOREIGN KEY (RuleId) REFERENCES VIB.ops_DataQualityRule (RuleId)
);
GO

CREATE NONCLUSTERED INDEX IX_ops_DataQualityRuleResult_ExecutionDate
    ON VIB.ops_DataQualityRuleResult (ExecutionDate DESC, RuleId);
GO

IF OBJECT_ID(N'VIB.ops_SavedQuery', N'U') IS NULL
CREATE TABLE VIB.ops_SavedQuery (
    QueryId             INT             IDENTITY(1,1) NOT NULL,
    Name                NVARCHAR(200)   NOT NULL,
    LayerCode           NVARCHAR(20)    NOT NULL,
    SqlText             NVARCHAR(MAX)   NOT NULL,
    CreatedByUserId     INT             NULL,
    CreatedAt           DATETIME2       NOT NULL CONSTRAINT DF_ops_SavedQuery_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_ops_SavedQuery PRIMARY KEY (QueryId),
    CONSTRAINT FK_ops_SavedQuery_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES VIB.sec_User (UserId)
);
GO

IF OBJECT_ID(N'VIB.ops_ReportDefinition', N'U') IS NULL
CREATE TABLE VIB.ops_ReportDefinition (
    ReportCode          NVARCHAR(50)    NOT NULL,
    Name                NVARCHAR(200)   NOT NULL,
    SourceLayer         NVARCHAR(20)    NOT NULL,
    ViewName            NVARCHAR(200)   NULL,
    StoredProcedureName NVARCHAR(200)   NULL,
    CONSTRAINT PK_ops_ReportDefinition PRIMARY KEY (ReportCode)
);
GO

IF OBJECT_ID(N'VIB.ops_ReportResultSnapshot', N'U') IS NULL
CREATE TABLE VIB.ops_ReportResultSnapshot (
    SnapshotId      INT             IDENTITY(1,1) NOT NULL,
    ReportCode      NVARCHAR(50)    NOT NULL,
    PeriodId        INT             NULL,
    JsonResult      NVARCHAR(MAX)   NULL,
    CreatedAt       DATETIME2       NOT NULL CONSTRAINT DF_ops_ReportResultSnapshot_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_ops_ReportResultSnapshot PRIMARY KEY (SnapshotId),
    CONSTRAINT FK_ops_ReportResultSnapshot_Report FOREIGN KEY (ReportCode) REFERENCES VIB.ops_ReportDefinition (ReportCode),
    CONSTRAINT FK_ops_ReportResultSnapshot_Period FOREIGN KEY (PeriodId) REFERENCES VIB.ops_ReconciliationPeriod (PeriodId)
);
GO

/* =============================================================================
   AUDIT  (logical schema: audit)
   ============================================================================= */

IF OBJECT_ID(N'VIB.audit_ActivityLog', N'U') IS NULL
CREATE TABLE VIB.audit_ActivityLog (
    LogId           INT             IDENTITY(1,1) NOT NULL,
    EventType       NVARCHAR(50)    NOT NULL,
    Title           NVARCHAR(200)   NOT NULL,
    Detail          NVARCHAR(500)   NULL,
    UserId          INT             NULL,
    CreatedAt       DATETIME2       NOT NULL CONSTRAINT DF_audit_ActivityLog_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_audit_ActivityLog PRIMARY KEY (LogId),
    CONSTRAINT FK_audit_ActivityLog_User FOREIGN KEY (UserId) REFERENCES VIB.sec_User (UserId)
);
GO

IF OBJECT_ID(N'VIB.audit_QueryExecutionLog', N'U') IS NULL
CREATE TABLE VIB.audit_QueryExecutionLog (
    LogId           INT             IDENTITY(1,1) NOT NULL,
    QueryId         INT             NULL,
    LayerCode       NVARCHAR(20)    NOT NULL,
    ExecutedAt      DATETIME2       NOT NULL CONSTRAINT DF_audit_QueryExecutionLog_ExecutedAt DEFAULT (SYSUTCDATETIME()),
    RowCount        INT             NULL,
    DurationMs      INT             NULL,
    ErrorMessage    NVARCHAR(MAX)   NULL,
    UserId          INT             NULL,
    CONSTRAINT PK_audit_QueryExecutionLog PRIMARY KEY (LogId),
    CONSTRAINT FK_audit_QueryExecutionLog_User FOREIGN KEY (UserId) REFERENCES VIB.sec_User (UserId)
);
GO

/* =============================================================================
   PORTAL VIEWS
   ============================================================================= */

IF OBJECT_ID(N'VIB.vw_PortalSummary', N'V') IS NOT NULL
    DROP VIEW VIB.vw_PortalSummary;
GO

CREATE VIEW VIB.vw_PortalSummary AS
SELECT
    (SELECT COUNT(*) FROM VIB.ops_CorporateAccount WHERE IsDeleted = 0) AS CorporateAccountCount,
    (SELECT COUNT(*) FROM VIB.ops_ReconciliationPeriod) AS ReconciliationPeriodCount,
    (SELECT COUNT(*) FROM VIB.ops_VarianceAccount WHERE IsDeleted = 0 AND Status IN (N'open', N'in_review')) AS OpenVarianceCount,
    (SELECT COUNT(*) FROM VIB.ops_ProcessTaskStatus WHERE Status IN (N'running', N'pending')) AS PendingTaskCount;
GO

IF OBJECT_ID(N'VIB.vw_TeamReconciliationProgress', N'V') IS NOT NULL
    DROP VIEW VIB.vw_TeamReconciliationProgress;
GO

CREATE VIEW VIB.vw_TeamReconciliationProgress AS
SELECT
    t.TeamId,
    t.Name AS TeamName,
    COUNT(v.VarianceId) AS TotalVarianceCount,
    SUM(CASE WHEN v.Status = N'closed' THEN 1 ELSE 0 END) AS ClosedVarianceCount,
    CASE
        WHEN COUNT(v.VarianceId) = 0 THEN 100
        ELSE CAST(SUM(CASE WHEN v.Status = N'closed' THEN 1 ELSE 0 END) * 100.0 / COUNT(v.VarianceId) AS INT)
    END AS ProgressPercent
FROM VIB.ref_Team t
LEFT JOIN VIB.ops_VarianceAccount v ON v.TeamId = t.TeamId AND v.IsDeleted = 0
WHERE t.IsActive = 1 AND t.IsDeleted = 0
GROUP BY t.TeamId, t.Name;
GO

IF OBJECT_ID(N'VIB.vw_TeamWorkload', N'V') IS NOT NULL
    DROP VIEW VIB.vw_TeamWorkload;
GO

CREATE VIEW VIB.vw_TeamWorkload AS
SELECT
    t.TeamId,
    t.Name AS TeamName,
    SUM(CASE WHEN v.Status IN (N'open', N'in_review') THEN 1 ELSE 0 END) AS OpenVarianceCount,
    SUM(CASE WHEN v.Status = N'open' THEN 1 ELSE 0 END) AS PendingActionCount
FROM VIB.ref_Team t
LEFT JOIN VIB.ops_VarianceAccount v ON v.TeamId = t.TeamId AND v.IsDeleted = 0
WHERE t.IsActive = 1 AND t.IsDeleted = 0
GROUP BY t.TeamId, t.Name;
GO
