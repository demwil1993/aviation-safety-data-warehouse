/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver) - Aviation Safety DWH
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.

    Actions Performed:
        - Truncates Silver tables.
        - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.

Usage Example:
    EXEC silver.LoadSilver;
===============================================================================
*/

USE AviationSafetyDWH;
GO

CREATE OR ALTER PROCEDURE silver.LoadSilver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime      DATETIME,
        @EndTime        DATETIME,
        @BatchStartTime DATETIME,
        @BatchEndTime   DATETIME;

    BEGIN TRY
        SET @BatchStartTime = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Layer (Aviation Safety DWH)';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading Reference Tables';
        PRINT '------------------------------------------------';

        /* =====================================================================
           Loading silver.RefOperator
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Truncating Table: silver.RefOperator';
        TRUNCATE TABLE silver.RefOperator;

        PRINT '>> Inserting Data Into: silver.RefOperator';
        INSERT INTO silver.RefOperator (
            OperatorCode,
            OperatorName,
            OperatorType,
            Country,
            FoundedYear,
            FleetSize,
            Alliance,
            IsActive
        )
        SELECT
            UPPER(TRIM(operator_code)) AS OperatorCode,
            NULLIF(TRIM(operator_name), '') AS OperatorName,
            NULLIF(UPPER(TRIM(operator_type)), '') AS OperatorType,
            NULLIF(TRIM(country), '') AS Country,
            TRY_CONVERT(INT, NULLIF(TRIM(founded_year), '')) AS FoundedYear,
            TRY_CONVERT(INT, TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(fleet_size), ''))) AS FleetSize,
            NULLIF(UPPER(TRIM(alliance)), '') AS Alliance,
            CASE
                WHEN UPPER(TRIM(is_active)) IN ('1', 'TRUE', 'Y', 'YES') THEN CONVERT(BIT, 1)
                WHEN UPPER(TRIM(is_active)) IN ('0', 'FALSE', 'N', 'NO') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS IsActive
        FROM (
            SELECT
                b.*,
                ROW_NUMBER() OVER (
                    PARTITION BY UPPER(TRIM(b.operator_code))
                    ORDER BY b.operator_code DESC
                ) AS flag_last
            FROM bronze.ref_operator b
            WHERE b.operator_code IS NOT NULL AND TRIM(b.operator_code) <> ''
        ) t
        WHERE t.flag_last = 1;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading silver.RefAirport
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Truncating Table: silver.RefAirport';
        TRUNCATE TABLE silver.RefAirport;

        PRINT '>> Inserting Data Into: silver.RefAirport';
        INSERT INTO silver.RefAirport (
            AirportCode,
            IataCode,
            AirportName,
            City,
            StateProvince,
            Country,
            Region,
            Latitude,
            Longitude,
            ElevationFt,
            AirportType,
            IsActive
        )
        SELECT
            UPPER(TRIM(airport_code)) AS AirportCode,
            NULLIF(UPPER(TRIM(iata_code)), '') AS IataCode,
            NULLIF(TRIM(airport_name), '') AS AirportName,
            NULLIF(TRIM(city), '') AS City,
            NULLIF(TRIM(state_province), '') AS StateProvince,
            NULLIF(TRIM(country), '') AS Country,
            CASE
                WHEN TRIM(region) = '' THEN NULL
                WHEN UPPER(TRIM(region)) = 'NA' THEN 'NORTH AMERICA'
                WHEN UPPER(TRIM(region)) = 'APAC' THEN 'ASIA PACIFIC'
                WHEN UPPER(TRIM(region)) = 'EU' THEN 'EUROPE'
                WHEN UPPER(TRIM(region)) = 'LATAM' THEN 'LATIN AMERICA'
                WHEN UPPER(TRIM(region)) = 'MEA' THEN 'MIDDLE EAST AND AFRICA'
                ELSE UPPER(TRIM(region))
            END AS Region,
            TRY_CONVERT(DECIMAL(9,6), NULLIF(TRIM(latitude), '')) AS Latitude,
            TRY_CONVERT(DECIMAL(9,6), NULLIF(TRIM(longitude), '')) AS Longitude,
            TRY_CONVERT(INT, TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(elevation_ft), ''))) AS ElevationFt,
            NULLIF(UPPER(TRIM(airport_type)), '') AS AirportType,
            CASE
                WHEN UPPER(TRIM(is_active)) IN ('1', 'TRUE', 'Y', 'YES') THEN CONVERT(BIT, 1)
                WHEN UPPER(TRIM(is_active)) IN ('0', 'FALSE', 'N', 'NO') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS IsActive
        FROM (
            SELECT
                b.*,
                ROW_NUMBER() OVER (
                    PARTITION BY UPPER(TRIM(b.airport_code))
                    ORDER BY b.airport_code DESC
                ) AS flag_last
            FROM bronze.ref_airport b
            WHERE b.airport_code IS NOT NULL AND TRIM(b.airport_code) <> ''
        ) t
        WHERE t.flag_last = 1;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading silver.RefAircraft
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Truncating Table: silver.RefAircraft';
        TRUNCATE TABLE silver.RefAircraft;

        PRINT '>> Inserting Data Into: silver.RefAircraft';
        INSERT INTO silver.RefAircraft (
            AircraftRegistration,
            AircraftTypeCode,
            Manufacturer,
            Model,
            ManufactureYear,
            OperatorCode,
            EngineType,
            EngineCount,
            MaxSeatingCapacity,
            AircraftCategory,
            IsActive
        )
        SELECT
            UPPER(TRIM(aircraft_registration)) AS AircraftRegistration,
            NULLIF(UPPER(TRIM(aircraft_type_code)), '') AS AircraftTypeCode,
            NULLIF(TRIM(manufacturer), '') AS Manufacturer,
            NULLIF(TRIM(model), '') AS Model,
            TRY_CONVERT(INT, TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(manufacture_year), ''))) AS ManufactureYear,
            NULLIF(UPPER(TRIM(operator_code)), '') AS OperatorCode,
            NULLIF(UPPER(TRIM(engine_type)), '') AS EngineType,
            TRY_CONVERT(TINYINT, NULLIF(TRIM(engine_count), '')) AS EngineCount,
            TRY_CONVERT(INT, TRY_CONVERT(DECIMAL(18,2), NULLIF(TRIM(max_seating_capacity), ''))) AS MaxSeatingCapacity,
            NULLIF(UPPER(TRIM(aircraft_category)), '') AS AircraftCategory,
            CASE
                WHEN UPPER(TRIM(is_active)) IN ('1', 'TRUE', 'Y', 'YES') THEN CONVERT(BIT, 1)
                WHEN UPPER(TRIM(is_active)) IN ('0', 'FALSE', 'N', 'NO') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS IsActive
        FROM (
            SELECT
                b.*,
                ROW_NUMBER() OVER (
                    PARTITION BY UPPER(TRIM(b.aircraft_registration))
                    ORDER BY b.aircraft_registration DESC
                ) AS flag_last
            FROM bronze.ref_aircraft b
            WHERE b.aircraft_registration IS NOT NULL AND TRIM(b.aircraft_registration) <> ''
        ) t
        WHERE t.flag_last = 1;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading Incident Tables';
        PRINT '------------------------------------------------';

        /* =====================================================================
           Loading silver.IncidentReports
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Truncating Table: silver.IncidentReports';
        TRUNCATE TABLE silver.IncidentReports;

        PRINT '>> Inserting Data Into: silver.IncidentReports';
        INSERT INTO silver.IncidentReports (
            IncidentId,
            ReportNumber,
            EventDate,
            AirportCode,
            OperatorCode,
            AircraftRegistration,
            AircraftTypeCode,
            FlightNumber,
            PhaseOfFlight,
            EventType,
            SeverityLevel,
            InjuriesCount,
            FatalitiesCount,
            AircraftDamageLevel,
            WeatherCondition,
            Narrative,
            ReportedBy,
            InvestigationStatus
        )
        SELECT
            UPPER(TRIM(t.incident_id)) AS IncidentId,
            NULLIF(TRIM(t.report_number), '') AS ReportNumber,
            TRY_CONVERT(DATE, NULLIF(TRIM(t.event_datetime), '')) AS EventDate,
            NULLIF(UPPER(TRIM(t.airport_code)), '') AS AirportCode,
            COALESCE(ra.OperatorCode, NULLIF(UPPER(TRIM(t.operator_code)), '')) AS OperatorCode,
            NULLIF(UPPER(TRIM(t.aircraft_registration)), '') AS AircraftRegistration,
            COALESCE(ra.AircraftTypeCode, NULLIF(UPPER(TRIM(t.aircraft_type_code)), '')) AS AircraftTypeCode,
            NULLIF(UPPER(TRIM(t.flight_number)), '') AS FlightNumber,
            NULLIF(UPPER(TRIM(t.phase_of_flight)), '') AS PhaseOfFlight,
            NULLIF(UPPER(TRIM(t.event_type)), '') AS EventType,
            NULLIF(UPPER(TRIM(t.severity_level)), '') AS SeverityLevel,
            TRY_CONVERT(INT, NULLIF(TRIM(t.injuries_count), '')) AS InjuriesCount,
            TRY_CONVERT(INT, NULLIF(TRIM(t.fatalities_count), '')) AS FatalitiesCount,
            NULLIF(UPPER(TRIM(t.aircraft_damage_level)), '') AS AircraftDamageLevel,
            NULLIF(UPPER(TRIM(t.weather_condition)), '') AS WeatherCondition,
            NULLIF(TRIM(LOWER(t.narrative)), '') AS Narrative,
            NULLIF(UPPER(TRIM(t.reported_by)), '') AS ReportedBy,
            NULLIF(UPPER(TRIM(t.investigation_status)), '') AS InvestigationStatus
        FROM (
            SELECT
                b.*,
                ROW_NUMBER() OVER (
                    PARTITION BY UPPER(TRIM(b.incident_id))
                    ORDER BY b.incident_id DESC
                ) AS flag_last
            FROM bronze.incident_reports b
            WHERE b.incident_id IS NOT NULL AND TRIM(b.incident_id) <> ''
        ) t
        LEFT JOIN silver.RefAircraft ra
            ON UPPER(TRIM(t.aircraft_registration)) = ra.AircraftRegistration
        WHERE t.flag_last = 1;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        SET @BatchEndTime = GETDATE();
        PRINT '==========================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @BatchStartTime, @BatchEndTime) AS NVARCHAR) + ' seconds';
        PRINT '==========================================' ;

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
        THROW;
    END CATCH
END
GO
