/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

USE AviationSafetyDWH;
GO

SELECT servicename, service_account
FROM sys.dm_server_services;
GO
-- ====================================================================
-- Checking Silver layer tables PRIMARY KEYs
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

WITH PrimaryKeyChecks AS (
    SELECT
        'silver.IncidentReports' AS TableName,
        'IncidentId' AS ColumnName,
        CAST(ir.IncidentId AS NVARCHAR(100)) AS KeyValue,
        COUNT(*) AS DuplicatesOrNull
    FROM silver.IncidentReports AS ir
    GROUP BY ir.IncidentId
    HAVING COUNT(*) > 1 OR ir.IncidentId IS NULL

    UNION ALL

    SELECT
        'silver.RefAircraft',
        'AircraftRegistration',
        CAST(a.AircraftRegistration AS NVARCHAR(100)),
        COUNT(*)
    FROM silver.RefAircraft AS a
    GROUP BY a.AircraftRegistration
    HAVING COUNT(*) > 1 OR a.AircraftRegistration IS NULL

    UNION ALL

    SELECT
        'silver.RefAirport',
        'AirportCode',
        CAST(a.AirportCode AS NVARCHAR(100)),
        COUNT(*)
    FROM silver.RefAirport AS a
    GROUP BY a.AirportCode
    HAVING COUNT(*) > 1 OR a.AirportCode IS NULL

    UNION ALL

    SELECT
        'silver.RefOperator',
        'OperatorCode',
        CAST(o.OperatorCode AS NVARCHAR(100)),
        COUNT(*)
    FROM silver.RefOperator AS o
    GROUP BY o.OperatorCode
    HAVING COUNT(*) > 1 OR o.OperatorCode IS NULL
)
SELECT *
FROM PrimaryKeyChecks
ORDER BY TableName, KeyValue;
GO

-- ====================================================================
-- Checking 'silver.IncidentReports'
-- ====================================================================
-- Check for unwanted spaces
-- Expectation: No results
SELECT
    ir.IncidentId
FROM silver.IncidentReports ir
WHERE ir.IncidentId <> TRIM(ir.IncidentId);
GO

SELECT
    ir.ReportNumber
FROM silver.IncidentReports ir
WHERE ir.ReportNumber <> TRIM(ir.ReportNumber);
GO

SELECT
    ir.AirportCode
FROM silver.IncidentReports ir
WHERE ir.AirportCode <> TRIM(ir.AirportCode);
GO

SELECT
    ir.FatalitiesCount
FROM silver.IncidentReports ir
WHERE ir.FatalitiesCount < 0 OR ir.FatalitiesCount IS NULL;
GO

-- ====================================================================
-- Checking 'silver.RefAircraft'
-- ====================================================================
-- Check for unwanted spaces
-- Expectation: No results

WITH QualityChecks AS (
    SELECT
        'AircraftRegistration' AS ColumnName,
        'Leading/Trailing Spaces' AS Issue,
        COUNT(*) AS InvalidCount
    FROM silver.RefAircraft
    WHERE AircraftRegistration <> TRIM(AircraftRegistration)

    UNION ALL

    SELECT
        'AircraftTypeCode',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAircraft
    WHERE AircraftTypeCode <> TRIM(AircraftTypeCode)

    UNION ALL

    SELECT
        'Manufacturer',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAircraft
    WHERE Manufacturer <> TRIM(Manufacturer)

    UNION ALL

    SELECT
        'Model',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAircraft
    WHERE Model <> TRIM(Model)

    UNION ALL

    SELECT
        'OperatorCode',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAircraft
    WHERE OperatorCode <> TRIM(OperatorCode)

    UNION ALL

    SELECT
        'EngineType',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAircraft
    WHERE EngineType <> TRIM(EngineType)

    UNION ALL

    SELECT
        'EngineCount',
        'Negative or NULL',
        COUNT(*)
    FROM silver.RefAircraft
    WHERE EngineCount < 0
       OR EngineCount IS NULL

    UNION ALL

    SELECT
        'MaxSeatingCapacity',
        'Negative or NULL',
        COUNT(*)
    FROM silver.RefAircraft
    WHERE MaxSeatingCapacity < 0
       OR MaxSeatingCapacity IS NULL

    UNION ALL

    SELECT
        'AircraftCategory',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAircraft
    WHERE AircraftCategory <> TRIM(AircraftCategory)
)
SELECT *
FROM QualityChecks
WHERE InvalidCount > 0
ORDER BY ColumnName;
GO

-- ====================================================================
-- Checking 'silver.RefAirport'
-- ====================================================================
-- Check for unwanted spaces
-- Expectation: No results

WITH QualityChecks AS (
    SELECT
        'AirportCode' AS ColumnName,
        'Leading/Trailing Spaces' AS Issue,
        COUNT(*) AS InvalidCount
    FROM silver.RefAirport
    WHERE AirportCode <> TRIM(AirportCode)

    UNION ALL

    SELECT
        'IataCode',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAirport
    WHERE IataCode <> TRIM(IataCode)

    UNION ALL

    SELECT
        'City',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAirport
    WHERE City <> TRIM(City)

    UNION ALL

    SELECT
        'StateProvince',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAirport
    WHERE StateProvince <> TRIM(StateProvince)

    UNION ALL

    SELECT
        'Country',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAirport
    WHERE Country <> TRIM(Country)

    UNION ALL

    SELECT
        'Region',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAirport
    WHERE Region <> TRIM(Region)

    UNION ALL

    SELECT
        'ElevationFt',
        'Negative or NULL',
        COUNT(*)
    FROM silver.RefAirport
    WHERE ElevationFt < 0
       OR ElevationFt IS NULL

    UNION ALL

    SELECT
        'AirportType',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefAirport
    WHERE AirportType <> TRIM(AirportType)
)
SELECT *
FROM QualityChecks
WHERE InvalidCount > 0
ORDER BY ColumnName;
GO

-- ====================================================================
-- Checking 'silver.RefOperator'
-- ====================================================================
-- Check for unwanted spaces
-- Expectation: No results
WITH QualityChecks AS (
    SELECT
        'OperatorCode' AS ColumnName,
        'Leading/Trailing Spaces' AS Issue,
        COUNT(*) AS InvalidCount
    FROM silver.RefOperator
    WHERE OperatorCode <> TRIM(OperatorCode)

    UNION ALL

    SELECT
        'OperatorName',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefOperator
    WHERE OperatorName <> TRIM(OperatorName)

    UNION ALL

    SELECT
        'OperatorType',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefOperator
    WHERE OperatorType <> TRIM(OperatorType)

    UNION ALL

    SELECT
        'Country',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefOperator
    WHERE Country <> TRIM(Country)

    UNION ALL

    SELECT
        'FoundedYear',
        'Negative or NULL',
        COUNT(*)
    FROM silver.RefOperator
    WHERE FoundedYear < 0
       OR FoundedYear IS NULL

    UNION ALL

    SELECT
        'Alliance',
        'Leading/Trailing Spaces',
        COUNT(*)
    FROM silver.RefOperator
    WHERE Alliance <> TRIM(Alliance)
)
SELECT *
FROM QualityChecks
WHERE InvalidCount > 0
ORDER BY ColumnName;
GO