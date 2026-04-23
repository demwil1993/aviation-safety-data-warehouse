/* =========================================================
   ETL LOGGING SETUP
   Database: SQL Server
   Purpose : Centralized logging for ETL pipeline runs
   ========================================================= */

SET NOCOUNT ON;
GO

/* =========================================================
   2) DROP VIEW FIRST IF RE-RUNNING
   ========================================================= */
IF OBJECT_ID('etl.vw_RunSummary', 'V') IS NOT NULL
    DROP VIEW etl.vw_RunSummary;
GO

/* =========================================================
   3) DROP PROCEDURES FIRST IF RE-RUNNING
   ========================================================= */
IF OBJECT_ID('etl.usp_EndStep', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_EndStep;
GO

IF OBJECT_ID('etl.usp_StartStep', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_StartStep;
GO

IF OBJECT_ID('etl.usp_EndRun', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_EndRun;
GO

IF OBJECT_ID('etl.usp_StartRun', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_StartRun;
GO

IF OBJECT_ID('etl.usp_LogTableCount', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_LogTableCount;
GO

/* =========================================================
   4) DROP TABLES IN CHILD-TO-PARENT ORDER IF RE-RUNNING
   ========================================================= */
IF OBJECT_ID('etl.StepTableCountLog', 'U') IS NOT NULL
    DROP TABLE etl.StepTableCountLog;
GO

IF OBJECT_ID('etl.StepLog', 'U') IS NOT NULL
    DROP TABLE etl.StepLog;
GO

IF OBJECT_ID('etl.RunLog', 'U') IS NOT NULL
    DROP TABLE etl.RunLog;
GO

/* =========================================================
   5) CREATE TABLE: RUN LOG
   One row per full ETL pipeline execution
   ========================================================= */
CREATE TABLE etl.RunLog
(
    RunId            INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_RunLog PRIMARY KEY,

    PipelineName     SYSNAME NOT NULL,
    RunStatus        VARCHAR(20) NOT NULL
        CONSTRAINT CK_RunLog_RunStatus
        CHECK (RunStatus IN ('Running', 'Succeeded', 'Failed')),

    StartTime        DATETIME2(3) NOT NULL
        CONSTRAINT DF_RunLog_StartTime DEFAULT SYSDATETIME(),

    EndTime          DATETIME2(3) NULL,

    DurationSeconds  DECIMAL(18,2) NULL,

    ServerName       SYSNAME NULL,
    DatabaseName     SYSNAME NULL,
    LoginName        SYSNAME NULL,
    HostName         SYSNAME NULL,
    ApplicationName  NVARCHAR(256) NULL,

    ErrorMessage     NVARCHAR(MAX) NULL,

    CreatedAt        DATETIME2(3) NOT NULL
        CONSTRAINT DF_RunLog_CreatedAt DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   6) CREATE TABLE: STEP LOG
   One row per ETL step within a run
   ========================================================= */
CREATE TABLE etl.StepLog
(
    StepLogId         INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_StepLog PRIMARY KEY,

    RunId             INT NOT NULL
        CONSTRAINT FK_StepLog_RunLog
        FOREIGN KEY REFERENCES etl.RunLog(RunId),

    StepName          VARCHAR(100) NOT NULL,
    ProcedureName     SYSNAME NOT NULL,
    TargetSchema      SYSNAME NULL,

    StepStatus        VARCHAR(20) NOT NULL
        CONSTRAINT CK_StepLog_StepStatus
        CHECK (StepStatus IN ('Running', 'Succeeded', 'Failed')),

    StartTime         DATETIME2(3) NOT NULL
        CONSTRAINT DF_StepLog_StartTime DEFAULT SYSDATETIME(),

    EndTime           DATETIME2(3) NULL,

    DurationSeconds   DECIMAL(18,2) NULL,

    RowsInserted      BIGINT NULL,
    RowsUpdated       BIGINT NULL,
    RowsDeleted       BIGINT NULL,

    ErrorMessage      NVARCHAR(MAX) NULL,

    CreatedAt         DATETIME2(3) NOT NULL
        CONSTRAINT DF_StepLog_CreatedAt DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   7) CREATE TABLE: STEP TABLE COUNT LOG
   Optional row-count snapshots after a step completes
   ========================================================= */
CREATE TABLE etl.StepTableCountLog
(
    CountLogId        INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_StepTableCountLog PRIMARY KEY,

    StepLogId         INT NOT NULL
        CONSTRAINT FK_StepTableCountLog_StepLog
        FOREIGN KEY REFERENCES etl.StepLog(StepLogId),

    TableName         NVARCHAR(256) NOT NULL,
    RowCountValue     BIGINT NOT NULL,

    LoggedAt          DATETIME2(3) NOT NULL
        CONSTRAINT DF_StepTableCountLog_LoggedAt DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   8) INDEXES
   ========================================================= */
CREATE INDEX IX_RunLog_StartTime
    ON etl.RunLog (StartTime DESC);
GO

CREATE INDEX IX_RunLog_RunStatus
    ON etl.RunLog (RunStatus, StartTime DESC);
GO

CREATE INDEX IX_StepLog_RunId
    ON etl.StepLog (RunId, StartTime);
GO

CREATE INDEX IX_StepLog_TargetSchema
    ON etl.StepLog (TargetSchema, StartTime DESC);
GO

CREATE INDEX IX_StepLog_StepStatus
    ON etl.StepLog (StepStatus, StartTime DESC);
GO

CREATE INDEX IX_StepTableCountLog_StepLogId
    ON etl.StepTableCountLog (StepLogId, LoggedAt DESC);
GO

/* =========================================================
   9) VIEW: RUN SUMMARY
   Easy reporting for SSMS / dashboards
   ========================================================= */
CREATE VIEW etl.vw_RunSummary
AS
SELECT
    r.RunId,
    r.PipelineName,
    r.RunStatus,
    r.StartTime      AS RunStartTime,
    r.EndTime        AS RunEndTime,
    r.DurationSeconds AS RunDurationSeconds,
    r.ServerName,
    r.DatabaseName,
    r.LoginName,
    r.HostName,
    r.ApplicationName,
    r.ErrorMessage   AS RunErrorMessage,

    s.StepLogId,
    s.StepName,
    s.ProcedureName,
    s.TargetSchema,
    s.StepStatus,
    s.StartTime      AS StepStartTime,
    s.EndTime        AS StepEndTime,
    s.DurationSeconds AS StepDurationSeconds,
    s.RowsInserted,
    s.RowsUpdated,
    s.RowsDeleted,
    s.ErrorMessage   AS StepErrorMessage
FROM etl.RunLog r
LEFT JOIN etl.StepLog s
    ON r.RunId = s.RunId;
GO

/* =========================================================
   10) PROCEDURE: START RUN
   Inserts a new pipeline run and returns RunId
   ========================================================= */
CREATE PROCEDURE etl.usp_StartRun
    @PipelineName SYSNAME,
    @RunId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO etl.RunLog
    (
        PipelineName,
        RunStatus,
        StartTime,
        ServerName,
        DatabaseName,
        LoginName,
        HostName,
        ApplicationName
    )
    VALUES
    (
        @PipelineName,
        'Running',
        SYSDATETIME(),
        @@SERVERNAME,
        DB_NAME(),
        SUSER_SNAME(),
        HOST_NAME(),
        APP_NAME()
    );

    SET @RunId = SCOPE_IDENTITY();
END
GO

/* =========================================================
   11) PROCEDURE: END RUN
   Marks run as Succeeded or Failed
   ========================================================= */
CREATE PROCEDURE etl.usp_EndRun
    @RunId INT,
    @RunStatus VARCHAR(20),
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE etl.RunLog
    SET
        RunStatus = @RunStatus,
        EndTime = SYSDATETIME(),
        DurationSeconds =
            DATEDIFF(MILLISECOND, StartTime, SYSDATETIME()) / 1000.0,
        ErrorMessage = @ErrorMessage
    WHERE RunId = @RunId;
END
GO

/* =========================================================
   12) PROCEDURE: START STEP
   Inserts a step row and returns StepLogId
   ========================================================= */
CREATE PROCEDURE etl.usp_StartStep
    @RunId INT,
    @StepName VARCHAR(100),
    @ProcedureName SYSNAME,
    @TargetSchema SYSNAME = NULL,
    @StepLogId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO etl.StepLog
    (
        RunId,
        StepName,
        ProcedureName,
        TargetSchema,
        StepStatus,
        StartTime
    )
    VALUES
    (
        @RunId,
        @StepName,
        @ProcedureName,
        @TargetSchema,
        'Running',
        SYSDATETIME()
    );

    SET @StepLogId = SCOPE_IDENTITY();
END
GO

/* =========================================================
   13) PROCEDURE: END STEP
   Marks step as Succeeded or Failed
   ========================================================= */
CREATE PROCEDURE etl.usp_EndStep
    @StepLogId INT,
    @StepStatus VARCHAR(20),
    @RowsInserted BIGINT = NULL,
    @RowsUpdated BIGINT = NULL,
    @RowsDeleted BIGINT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE etl.StepLog
    SET
        StepStatus = @StepStatus,
        EndTime = SYSDATETIME(),
        DurationSeconds =
            DATEDIFF(MILLISECOND, StartTime, SYSDATETIME()) / 1000.0,
        RowsInserted = @RowsInserted,
        RowsUpdated = @RowsUpdated,
        RowsDeleted = @RowsDeleted,
        ErrorMessage = @ErrorMessage
    WHERE StepLogId = @StepLogId;
END
GO

/* =========================================================
   14) PROCEDURE: LOG TABLE COUNT
   Used after a step succeeds to snapshot counts
   ========================================================= */
CREATE PROCEDURE etl.usp_LogTableCount
    @StepLogId INT,
    @TableName NVARCHAR(256),
    @RowCountValue BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO etl.StepTableCountLog
    (
        StepLogId,
        TableName,
        RowCountValue
    )
    VALUES
    (
        @StepLogId,
        @TableName,
        @RowCountValue
    );
END
GO