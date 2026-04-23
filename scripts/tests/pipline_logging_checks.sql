USE AviationSafetyDWH;
GO

/* =========================================================
   15) EXAMPLE QUERIES
   ========================================================= */

-- Most recent runs
SELECT TOP (20)
    RunId,
    PipelineName,
    RunStatus,
    StartTime,
    EndTime,
    DurationSeconds,
    ErrorMessage
FROM etl.RunLog
ORDER BY RunId DESC;
GO

-- Most recent step executions
SELECT TOP (50)
    StepLogId,
    RunId,
    StepName,
    ProcedureName,
    TargetSchema,
    StepStatus,
    StartTime,
    EndTime,
    DurationSeconds,
    ErrorMessage
FROM etl.StepLog
ORDER BY StepLogId DESC;
GO

-- Count snapshots
SELECT TOP (50)
    c.CountLogId,
    c.StepLogId,
    c.TableName,
    c.RowCountValue,
    c.LoggedAt
FROM etl.StepTableCountLog c
ORDER BY c.CountLogId DESC;
GO

-- Combined summary
SELECT TOP (100) *
FROM etl.vw_RunSummary
ORDER BY RunId DESC, StepLogId DESC;
GO