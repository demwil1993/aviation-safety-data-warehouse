USE AviationSafetyDWH;
GO

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

-- ====================================================================
-- Checking 'silver.IncidentReports'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT servicename, service_account
FROM sys.dm_server_services;
GO

SELECT
    ir.IncidentId,
    COUNT(*)
FROM silver.IncidentReports ir
GROUP BY ir.IncidentId
HAVING COUNT(*) > 1 OR ir.IncidentId IS NULL;

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
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT
    a.AircraftRegistration,
    COUNT(*)
FROM silver.RefAircraft a
GROUP BY a.AircraftRegistration
HAVING COUNT(*) > 1 or a.AircraftRegistration IS NULL;
GO

-- Check for unwanted spaces
-- Expectation: No results
SELECT
    a.AircraftRegistration
FROM silver.RefAircraft a
WHERE a.AircraftRegistration <> TRIM(a.AircraftRegistration);
GO

SELECT
    a.AircraftTypeCode
FROM silver.RefAircraft a
WHERE a.AircraftTypeCode <> TRIM(a.AircraftTypeCode);
GO

SELECT
    a.Manufacturer
FROM silver.RefAircraft a
WHERE a.Manufacturer <> TRIM(a.Manufacturer);
GO

SELECT
    a.Model
FROM silver.RefAircraft a
WHERE a.Model <> TRIM(a.Model);
GO

SELECT
    a.OperatorCode
FROM silver.RefAircraft a
WHERE a.OperatorCode <> TRIM(a.OperatorCode);
GO

SELECT
    a.EngineType
FROM silver.RefAircraft a
WHERE a.EngineType <> TRIM(a.EngineType);
GO

SELECT
    a.EngineCount
FROM silver.RefAircraft a
WHERE a.EngineCount < 0 OR a.EngineCount IS NULL;
GO

SELECT
    a.AircraftRegistration,
    a.Model,
    a.MaxSeatingCapacity
FROM silver.RefAircraft a
WHERE a.MaxSeatingCapacity < 0 OR a.MaxSeatingCapacity IS NULL;
GO

SELECT
    a.AircraftCategory
FROM silver.RefAircraft a
WHERE a.AircraftCategory <> TRIM(a.AircraftCategory);
GO

-- ====================================================================
-- Checking 'silver.RefAirport'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT
    a.AirportCode,
    COUNT(*)
FROM silver.RefAirport a
GROUP BY a.AirportCode
HAVING COUNT(*) > 1 OR a.AirportCode IS NULL;
GO

-- Check for unwanted spaces
-- Expectation: No results

SELECT
    a.AirportCode
FROM silver.RefAirport a
WHERE a.AirportCode <> TRIM(a.AirportCode);
GO

SELECT
    a.IataCode
FROM silver.RefAirport a
WHERE a.IataCode <> TRIM(a.IataCode);
GO

SELECT
    a.City
FROM silver.RefAirport a
WHERE a.City <> TRIM(a.City);
GO

SELECT
    a.StateProvince
FROM silver.RefAirport a
WHERE a.StateProvince <> TRIM(a.StateProvince);
GO

SELECT
    a.Country
FROM silver.RefAirport a
WHERE a.Country <> TRIM(a.Country) OR a.Country IS NULL;
GO

SELECT
    a.Region
FROM silver.RefAirport a
WHERE a.Region <> TRIM(a.Region);
GO

SELECT
    a.ElevationFt
FROM silver.RefAirport a
WHERE a.ElevationFt < 0 OR a.ElevationFt IS NULL;
GO

SELECT
    a.AirportType
FROM silver.RefAirport a
WHERE a.AirportType <> TRIM(a.AirportType);
GO

-- ====================================================================
-- Checking 'silver.RefOperator'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT
    o.OperatorCode,
    COUNT(*)
FROM silver.RefOperator o
GROUP BY o.OperatorCode
HAVING COUNT(*) > 1 OR o.OperatorCode IS NULL;
GO

-- Check for unwanted spaces
-- Expectation: No results
SELECT
    o.OperatorCode
FROM silver.RefOperator o
WHERE o.OperatorCode <> TRIM(o.OperatorCode);
GO

SELECT
    o.OperatorName
FROM silver.RefOperator o
WHERE o.OperatorName <> TRIM(o.OperatorName);
GO

SELECT
    o.OperatorType
FROM silver.RefOperator o
WHERE o.OperatorType <> TRIM(o.OperatorType);
GO

SELECT
    o.Country
FROM silver.RefOperator o
WHERE o.Country <> TRIM(o.Country);
GO

SELECT 
    o.FoundedYear    
FROM silver.RefOperator o
WHERE o.FoundedYear < 0 OR o.FoundedYear IS NULL;
GO

SELECT
    o.Alliance
FROM silver.RefOperator o
WHERE o.Alliance <> TRIM(o.Alliance);
GO