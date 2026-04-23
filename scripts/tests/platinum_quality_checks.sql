USE AviationSafetyDWH;
GO

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
-- Checking 'platinum.DimAircraft'
-- ====================================================================
-- Check for Uniqueness of Aircraft Key in platinum.DimAircraft
-- Expectation: No results 

SELECT
    da.AircraftKey,
    COUNT(*) duplicates
FROM platinum.DimAircraft da
GROUP BY da.AircraftKey
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'platinum.DimAircraftLevelKey'
-- ====================================================================
-- Check for Uniqueness of Aircraft Damage Level Key in platinum.DimAircraftLevelKey
-- Expectation: No results 
SELECT
    dl.AircraftDamageLevelKey,
    COUNT(*) duplicates
FROM platinum.DimAircraftDamageLevel dl
GROUP BY dl.AircraftDamageLevelKey
HAVING COUNT(*) > 1;