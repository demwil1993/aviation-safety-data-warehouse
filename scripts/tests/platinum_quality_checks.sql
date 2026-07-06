/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking Dimension Tables
-- ====================================================================
-- Check for Uniqueness of Primary Key in dimension tables
-- Expectation: No results 

USE AviationSafetyDWH;
GO

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimAircraft' AS TableName,
    CAST(da.AircraftKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimAircraft AS da
GROUP BY da.AircraftKey
HAVING COUNT(*) > 1 OR da.AircraftKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimAircraftDamageLevel' AS TableName,
    CAST(dl.AircraftDamageLevelKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimAircraftDamageLevel AS dl
GROUP BY dl.AircraftDamageLevelKey
HAVING COUNT(*) > 1 OR dl.AircraftDamageLevelKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimAirport' AS TableName,
    CAST(dp.AirportKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimAirport AS dp
GROUP BY dp.AirportKey
HAVING COUNT(*) > 1 OR dp.AirportKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimDate' AS TableName,
    CAST(dd.DateKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimDate AS dd
GROUP BY dd.DateKey
HAVING COUNT(*) > 1 OR dd.DateKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimEventType' AS TableName,
    CAST(de.EventTypeKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimEventType AS de
GROUP BY de.EventTypeKey
HAVING COUNT(*) > 1 OR de.EventTypeKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimInvestigationStatus' AS TableName,
    CAST(dis.InvestigationStatusKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimInvestigationStatus AS dis
GROUP BY dis.InvestigationStatusKey
HAVING COUNT(*) > 1 OR dis.InvestigationStatusKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimOperator' AS TableName,
    CAST(do.OperatorKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimOperator AS do
GROUP BY do.OperatorKey
HAVING COUNT(*) > 1 OR do.OperatorKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimPhaseOfFlight' AS TableName,
    CAST(dpf.PhaseOfFlightKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimPhaseOfFlight AS dpf
GROUP BY dpf.PhaseOfFlightKey
HAVING COUNT(*) > 1 OR dpf.PhaseOfFlightKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimReportedBy' AS TableName,
    CAST(drb.ReportedByKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimReportedBy drb
GROUP BY drb.ReportedByKey
HAVING COUNT(*) > 1 OR drb.ReportedByKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimSeverity' AS TableName,
    CAST(ds.SeverityKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimSeverity AS ds
GROUP BY ds.SeverityKey
HAVING COUNT(*) > 1 OR ds.SeverityKey IS NULL

UNION ALL

SELECT
    'Primary Key Uniqueness / Null Check' AS CheckName,
    'platinum.DimWeatherCondition' AS TableName,
    CAST(dwc.WeatherConditionKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(*) AS IssueCount
FROM platinum.DimWeatherCondition AS dwc
GROUP BY dwc.WeatherConditionKey
HAVING COUNT(*) > 1 OR dwc.WeatherConditionKey IS NULL;
GO

-- ====================================================================
-- Checking Referential integrity
-- ====================================================================
-- Check for referential integrity between fact and dimension tables.
-- Expectation: No results 
SELECT
    'AircraftKey' AS ForeignKey,
    CAST(f.AircraftKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimAircraft AS da
    ON da.AircraftKey = f.AircraftKey
WHERE da.AircraftKey IS NULL
GROUP BY f.AircraftKey

UNION ALL

SELECT
    'AircraftDamageLevelKey' AS ForeignKey,
    CAST(f.AircraftDamageLevelKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimAircraftDamageLevel AS dl
    ON dl.AircraftDamageLevelKey = f.AircraftDamageLevelKey
WHERE dl.AircraftDamageLevelKey IS NULL
GROUP BY f.AircraftDamageLevelKey

UNION ALL

SELECT
    'AirportKey' AS ForeignKey,
    CAST(f.AirportKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimAirport AS dai
    ON dai.AirportKey = f.AirportKey
WHERE dai.AirportKey IS NULL
GROUP BY f.AirportKey

UNION ALL

SELECT
    'DateKey' AS ForeignKey,
    CAST(f.DateKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimDate AS dd
    ON dd.DateKey = f.DateKey
WHERE dd.DateKey IS NULL
GROUP BY f.DateKey

UNION ALL

SELECT
    'EventTypeKey' AS ForeignKey,
    CAST(f.EventTypeKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimEventType AS det
    ON det.EventTypeKey = f.EventTypeKey
WHERE det.EventTypeKey IS NULL
GROUP BY f.EventTypeKey

UNION ALL

SELECT
    'InvestigationStatusKey' AS ForeignKey,
    CAST(f.InvestigationStatusKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimInvestigationStatus AS dis
    ON dis.InvestigationStatusKey = f.InvestigationStatusKey
WHERE dis.InvestigationStatusKey IS NULL
GROUP BY f.InvestigationStatusKey

UNION ALL

SELECT
    'OperatorKey' AS ForeignKey,
    CAST(f.OperatorKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimOperator AS do
    ON do.OperatorKey = f.OperatorKey
WHERE do.OperatorKey IS NULL
GROUP BY f.OperatorKey

UNION ALL

SELECT
    'PhaseOfFlightKey' AS ForeignKey,
    CAST(f.PhaseOfFlightKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimPhaseOfFlight AS dpf
    ON dpf.PhaseOfFlightKey = f.PhaseOfFlightKey
WHERE dpf.PhaseOfFlightKey IS NULL
GROUP BY f.PhaseOfFlightKey

UNION ALL

SELECT
    'ReportedByKey' AS ForeignKey,
    CAST(f.ReportedByKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimReportedBy AS drb
    ON drb.ReportedByKey = f.ReportedByKey
WHERE drb.ReportedByKey IS NULL
GROUP BY f.ReportedByKey

UNION ALL

SELECT
    'SeverityKey' AS ForeignKey,
    CAST(f.SeverityKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimSeverity AS ds
    ON ds.SeverityKey = f.SeverityKey
WHERE ds.SeverityKey IS NULL
GROUP BY f.SeverityKey

UNION ALL

SELECT
    'WeatherConditionKey' AS ForeignKey,
    CAST(f.WeatherConditionKey AS NVARCHAR(50)) AS KeyValue,
    COUNT(f.IncidentId) AS OrphanedRows
FROM platinum.FactIncidents AS f
LEFT JOIN platinum.DimWeatherCondition AS dwc
    ON dwc.WeatherConditionKey = f.WeatherConditionKey
WHERE dwc.WeatherConditionKey IS NULL
GROUP BY f.WeatherConditionKey

ORDER BY ForeignKey, KeyValue;
GO