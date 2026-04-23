/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze) - Aviation Safety DWH
===============================================================================
Script Purpose:
    Loads data into the 'bronze' schema from external source files.
    - Truncates bronze tables before loading.
    - Uses OPENROWSET + OPENJSON to load JSON reference files.
    - Uses BULK INSERT to load CSV incident data.
    - Reads source file paths from dbo.etl_config.
    - Keeps bronze as raw landing zone (no datatype corrections here).
    - Prints progress + per-table durations + total duration.
===============================================================================
Dependencies:
    - config.etl_config must contain the required config keys.
===============================================================================
Usage Example:
    EXEC bronze.LoadBronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.LoadBronze AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @StartTime DATETIME,
        @EndTime DATETIME,
        @BatchStartTime DATETIME,
        @BatchEndTime DATETIME,
        @RefOperatorPath NVARCHAR(1000),
        @RefAirportPath NVARCHAR(1000),
        @RefAircraftPath NVARCHAR(1000),
        @IncidentReportsPath NVARCHAR(1000),
        @sql NVARCHAR(MAX);

    BEGIN TRY
        SET @BatchStartTime = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Bronze Layer (Aviation Safety DWH)';
        PRINT '================================================';

        -- ========================================
        -- Read required file paths from config table
        -- ========================================
        SELECT @RefOperatorPath = ConfigValue
        FROM config.EtlConfig
        WHERE ConfigKey = 'RefOperatorPath';

        SELECT @RefAirportPath = ConfigValue
        FROM config.EtlConfig
        WHERE ConfigKey = 'RefAirportPath';

        SELECT @RefAircraftPath = ConfigValue
        FROM config.EtlConfig
        WHERE ConfigKey = 'RefAircraftPath';

        SELECT @IncidentReportsPath = ConfigValue
        FROM config.EtlConfig
        WHERE ConfigKey = 'IncidentReportsPath';

        IF @RefOperatorPath IS NULL
            THROW 50001, 'Missing config: RefOperatorPath', 1;

        IF @RefAirportPath IS NULL
            THROW 50002, 'Missing config: RefAirportPath', 1;

        IF @RefAircraftPath IS NULL
            THROW 50003, 'Missing config: RefAircraftPath', 1;

        IF @IncidentReportsPath IS NULL
            THROW 50004, 'Missing config: IncidentReportsPath', 1;

        PRINT '------------------------------------------------';
        PRINT 'Loading Reference Tables';
        PRINT '------------------------------------------------';

        -- =========================
        -- bronze.ref_operator (JSON)
        -- =========================
        SET @StartTime = GETDATE();
        PRINT '>> Truncating Table: bronze.ref_operator';
        TRUNCATE TABLE bronze.ref_operator;

        PRINT '>> Inserting Data Into: bronze.ref_operator';

        SET @sql = N'
        INSERT INTO bronze.ref_operator
        (
            operator_code,
            operator_name,
            operator_type,
            country,
            founded_year,
            fleet_size,
            alliance,
            is_active,
            created_at
        )
        SELECT
            j.operator_code,
            j.operator_name,
            j.operator_type,
            j.country,
            j.founded_year,
            j.fleet_size,
            j.alliance,
            j.is_active,
            j.created_at
        FROM OPENROWSET
        (
            BULK ''' + REPLACE(@RefOperatorPath, '''', '''''') + ''',
            SINGLE_CLOB
        ) AS src
        CROSS APPLY OPENJSON(src.BulkColumn)
        WITH
        (
            operator_code NVARCHAR(50)  ''$.operator_code'',
            operator_name NVARCHAR(255) ''$.operator_name'',
            operator_type NVARCHAR(50)  ''$.operator_type'',
            country       NVARCHAR(100) ''$.country'',
            founded_year  NVARCHAR(50)  ''$.founded_year'',
            fleet_size    NVARCHAR(50)  ''$.fleet_size'',
            alliance      NVARCHAR(50)  ''$.alliance'',
            is_active     NVARCHAR(10)  ''$.is_active'',
            created_at    NVARCHAR(50)  ''$.created_at''
        ) AS j;';

        EXEC sp_executesql @sql;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- =========================
        -- bronze.ref_airport (JSON)
        -- =========================
        SET @StartTime = GETDATE();
        PRINT '>> Truncating Table: bronze.ref_airport';
        TRUNCATE TABLE bronze.ref_airport;

        PRINT '>> Inserting Data Into: bronze.ref_airport';

        SET @sql = N'
        INSERT INTO bronze.ref_airport
        (
            airport_code,
            iata_code,
            airport_name,
            city,
            state_province,
            country,
            region,
            latitude,
            longitude,
            elevation_ft,
            airport_type,
            is_active,
            created_at
        )
        SELECT
            j.airport_code,
            j.iata_code,
            j.airport_name,
            j.city,
            j.state_province,
            j.country,
            j.region,
            j.latitude,
            j.longitude,
            j.elevation_ft,
            j.airport_type,
            j.is_active,
            j.created_at
        FROM OPENROWSET
        (
            BULK ''' + REPLACE(@RefAirportPath, '''', '''''') + ''',
            SINGLE_CLOB
        ) AS src
        CROSS APPLY OPENJSON(src.BulkColumn)
        WITH
        (
            airport_code     NVARCHAR(50)   ''$.airport_code'',
            iata_code        NVARCHAR(50)   ''$.iata_code'',
            airport_name     NVARCHAR(255)  ''$.airport_name'',
            city             NVARCHAR(100)  ''$.city'',
            state_province   NVARCHAR(100)  ''$.state_province'',
            country          NVARCHAR(100)  ''$.country'',
            region           NVARCHAR(50)   ''$.region'',
            latitude         NVARCHAR(50)   ''$.latitude'',
            longitude        NVARCHAR(50)   ''$.longitude'',
            elevation_ft     NVARCHAR(50)   ''$.elevation_ft'',
            airport_type     NVARCHAR(50)   ''$.airport_type'',
            is_active        NVARCHAR(10)   ''$.is_active'',
            created_at       NVARCHAR(50)   ''$.created_at''
        ) AS j;';

        EXEC sp_executesql @sql;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- =========================
        -- bronze.ref_aircraft (JSON)
        -- =========================
        SET @StartTime = GETDATE();
        PRINT '>> Truncating Table: bronze.ref_aircraft';
        TRUNCATE TABLE bronze.ref_aircraft;

        PRINT '>> Inserting Data Into: bronze.ref_aircraft';

        SET @sql = N'
        INSERT INTO bronze.ref_aircraft
        (
            aircraft_registration,
            aircraft_type_code,
            manufacturer,
            model,
            manufacture_year,
            operator_code,
            engine_type,
            engine_count,
            max_seating_capacity,
            aircraft_category,
            is_active,
            created_at
        )
        SELECT
            j.aircraft_registration,
            j.aircraft_type_code,
            j.manufacturer,
            j.model,
            j.manufacture_year,
            j.operator_code,
            j.engine_type,
            j.engine_count,
            j.max_seating_capacity,
            j.aircraft_category,
            j.is_active,
            j.created_at
        FROM OPENROWSET
        (
            BULK ''' + REPLACE(@RefAircraftPath, '''', '''''') + ''',
            SINGLE_CLOB
        ) AS src
        CROSS APPLY OPENJSON(src.BulkColumn)
        WITH
        (
            aircraft_registration   NVARCHAR(50)    ''$.aircraft_registration'',
            aircraft_type_code      NVARCHAR(50)    ''$.aircraft_type_code'',
            manufacturer            NVARCHAR(100)   ''$.manufacturer'',
            model                   NVARCHAR(100)   ''$.model'',
            manufacture_year        NVARCHAR(50)    ''$.manufacture_year'',
            operator_code           NVARCHAR(50)    ''$.operator_code'',
            engine_type             NVARCHAR(50)    ''$.engine_type'',
            engine_count            NVARCHAR(50)    ''$.engine_count'',
            max_seating_capacity    NVARCHAR(50)    ''$.max_seating_capacity'',
            aircraft_category       NVARCHAR(50)    ''$.aircraft_category'',
            is_active               NVARCHAR(10)    ''$.is_active'',
            created_at              NVARCHAR(50)    ''$.created_at''
        ) AS j;';

        EXEC sp_executesql @sql;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        PRINT '------------------------------------------------';
        PRINT 'Loading Incident Tables';
        PRINT '------------------------------------------------';

        -- =========================
        -- bronze.incident_reports
        -- =========================
        SET @StartTime = GETDATE();
        PRINT '>> Truncating Table: bronze.incident_reports';
        TRUNCATE TABLE bronze.incident_reports;

        PRINT '>> Inserting Data Into: bronze.incident_reports';

        SET @sql = N'
        BULK INSERT bronze.incident_reports
        FROM ''' + REPLACE(@IncidentReportsPath, '''', '''''') + '''
        WITH (
            FORMAT = ''CSV'',
            FIRSTROW = 2,
            FIELDQUOTE = ''"'',
            TABLOCK
        );';

        EXEC sp_executesql @sql;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @BatchEndTime = GETDATE();
        PRINT '=========================================='
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @BatchStartTime, @BatchEndTime) AS NVARCHAR) + ' seconds';
        PRINT '=========================================='

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
        THROW;
    END CATCH
END
GO
