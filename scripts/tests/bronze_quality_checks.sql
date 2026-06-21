/*
===================================================================================
Bronze Layer Data Quality Summary
Aviation Safety Data Warehouse
===================================================================================

Purpose:
    This script provides lightweight data quality checks on the bronze layer
    to document the condition of raw source data after ingestion.

Key Design Principles:
    - Bronze represents data as received from the source system
    - No business rules or transformations are applied at this stage
    - Data quality issues observed here are assumed to originate from source

Scope of Checks:
    - Row counts per table (load completeness)
    - Null / blank values in key source fields
    - Duplicate raw identifiers
    - Raw values that may fail type conversion in silver layer

Important Notes:
    - NULL values in bronze are preserved intentionally to reflect source data
    - Example: 'max_seating_capacity' contains NULLs in source and is not modified
    - Downstream layers (silver/platinum/gold) are responsible for:
        - standardization
        - business rule enforcement
        - presentation handling of missing values

Usage:
    - Run after bronze load completes
    - Use results to trace data quality issues back to source systems
    - Not intended to block pipeline execution

===================================================================================
*/

/*
===================================================================================
Bronze Layer Data Quality Summary (Single Result Set)
===================================================================================
Columns:
    TableName   - Source table
    CheckName   - Type of check
    IssueCount  - Number of records failing / matching condition
===================================================================================
*/

USE AviationSafetyDWH;
GO

CREATE OR ALTER PROCEDURE bronze.DataQualityCheck AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM (

        --------------------------------------------------------------------------------
        -- 1) Row Counts
        --------------------------------------------------------------------------------
        SELECT 'bronze.ref_operator' AS TableName, 'ROW_COUNT' AS CheckName, COUNT(*) AS IssueCount
        FROM bronze.ref_operator

        UNION ALL
        SELECT 'bronze.ref_airport', 'ROW_COUNT', COUNT(*) FROM bronze.ref_airport

        UNION ALL
        SELECT 'bronze.ref_aircraft', 'ROW_COUNT', COUNT(*) FROM bronze.ref_aircraft

        UNION ALL
        SELECT 'bronze.incident_reports', 'ROW_COUNT', COUNT(*) FROM bronze.incident_reports


        --------------------------------------------------------------------------------
        -- 2) Null / Blank Checks (key columns only to keep it lightweight)
        --------------------------------------------------------------------------------
        UNION ALL
        SELECT 'bronze.ref_aircraft', 'max_seating_capacity_null_or_blank',
               COUNT(*)
        FROM bronze.ref_aircraft
        WHERE max_seating_capacity IS NULL OR TRIM(max_seating_capacity) = ''

        UNION ALL
        SELECT 'bronze.ref_aircraft', 'aircraft_registration_null_or_blank',
               COUNT(*)
        FROM bronze.ref_aircraft
        WHERE aircraft_registration IS NULL OR TRIM(aircraft_registration) = ''

        UNION ALL
        SELECT 'bronze.ref_airport', 'airport_code_null_or_blank',
               COUNT(*)
        FROM bronze.ref_airport
        WHERE airport_code IS NULL OR TRIM(airport_code) = ''

        UNION ALL
        SELECT 'bronze.ref_operator', 'operator_code_null_or_blank',
               COUNT(*)
        FROM bronze.ref_operator
        WHERE operator_code IS NULL OR TRIM(operator_code) = ''

        UNION ALL
        SELECT 'bronze.incident_reports', 'incident_id_null_or_blank',
               COUNT(*)
        FROM bronze.incident_reports
        WHERE incident_id IS NULL OR TRIM(incident_id) = ''


        --------------------------------------------------------------------------------
        -- 3) Duplicate Key Checks
        --------------------------------------------------------------------------------
        UNION ALL
        SELECT 'bronze.ref_operator', 'duplicate_operator_code',
               COUNT(*)
        FROM (
            SELECT operator_code
            FROM bronze.ref_operator
            WHERE operator_code IS NOT NULL AND TRIM(operator_code) <> ''
            GROUP BY operator_code
            HAVING COUNT(*) > 1
        ) d

        UNION ALL
        SELECT 'bronze.ref_airport', 'duplicate_airport_code',
               COUNT(*)
        FROM (
            SELECT airport_code
            FROM bronze.ref_airport
            WHERE airport_code IS NOT NULL AND TRIM(airport_code) <> ''
            GROUP BY airport_code
            HAVING COUNT(*) > 1
        ) d

        UNION ALL
        SELECT 'bronze.ref_aircraft', 'duplicate_aircraft_registration',
               COUNT(*)
        FROM (
            SELECT aircraft_registration
            FROM bronze.ref_aircraft
            WHERE aircraft_registration IS NOT NULL AND TRIM(aircraft_registration) <> ''
            GROUP BY aircraft_registration
            HAVING COUNT(*) > 1
        ) d

        UNION ALL
        SELECT 'bronze.incident_reports', 'duplicate_incident_id',
               COUNT(*)
        FROM (
            SELECT incident_id
            FROM bronze.incident_reports
            WHERE incident_id IS NOT NULL AND TRIM(incident_id) <> ''
            GROUP BY incident_id
            HAVING COUNT(*) > 1
        ) d


        --------------------------------------------------------------------------------
        -- 4) Conversion Risk Checks (values that will fail in silver)
        --------------------------------------------------------------------------------
        UNION ALL
        SELECT 'bronze.ref_aircraft', 'invalid_max_seating_capacity_format',
               COUNT(*)
        FROM bronze.ref_aircraft
        WHERE NULLIF(TRIM(max_seating_capacity), '') IS NOT NULL
          AND TRY_CONVERT(INT, TRY_CONVERT(DECIMAL(18,2), TRIM(max_seating_capacity))) IS NULL

        UNION ALL
        SELECT 'bronze.ref_aircraft', 'invalid_engine_count_format',
               COUNT(*)
        FROM bronze.ref_aircraft
        WHERE NULLIF(TRIM(engine_count), '') IS NOT NULL
          AND TRY_CONVERT(INT, TRIM(engine_count)) IS NULL

        UNION ALL
        SELECT 'bronze.ref_airport', 'invalid_lat_long_format',
               COUNT(*)
        FROM bronze.ref_airport
        WHERE (NULLIF(TRIM(latitude), '') IS NOT NULL AND TRY_CONVERT(DECIMAL(18,6), TRIM(latitude)) IS NULL)
           OR (NULLIF(TRIM(longitude), '') IS NOT NULL AND TRY_CONVERT(DECIMAL(18,6), TRIM(longitude)) IS NULL)

        UNION ALL
        SELECT 'bronze.incident_reports', 'invalid_event_datetime_format',
               COUNT(*)
        FROM bronze.incident_reports
        WHERE NULLIF(TRIM(event_datetime), '') IS NOT NULL
          AND TRY_CONVERT(DATETIME2, TRIM(event_datetime)) IS NULL

        UNION ALL
        SELECT 'bronze.incident_reports', 'invalid_injuries_count_format',
               COUNT(*)
        FROM bronze.incident_reports
        WHERE NULLIF(TRIM(injuries_count), '') IS NOT NULL
          AND TRY_CONVERT(INT, TRIM(injuries_count)) IS NULL

        UNION ALL
        SELECT 'bronze.incident_reports', 'invalid_fatalities_count_format',
               COUNT(*)
        FROM bronze.incident_reports
        WHERE NULLIF(TRIM(fatalities_count), '') IS NOT NULL
          AND TRY_CONVERT(INT, TRIM(fatalities_count)) IS NULL

    ) dq
    ORDER BY TableName, CheckName;
END
GO