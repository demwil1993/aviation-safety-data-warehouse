/*
===============================================================================
Stored Procedure: Load Platinum Layer (Silver -> Platinum) - Aviation Safety DWH
===============================================================================
Script Purpose:
    This stored procedure performs the ETL process to populate the 'platinum'
    schema tables from the 'silver' schema.

    Actions Performed:
        - Truncates Platinum fact table, then Platinum dimension tables.
        - Inserts seeded unknown (-1) members into all dimensions.
        - Inserts transformed / conformed dimensional data from Silver into Platinum.
        - Loads fact table by resolving business keys to surrogate keys.

Parameters:
    None.

Usage Example:
    EXEC platinum.LoadPlatinum;
===============================================================================
*/

USE AviationSafetyDWH;
GO

CREATE OR ALTER PROCEDURE platinum.LoadPlatinum
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime       DATETIME,
        @EndTime         DATETIME,
        @BatchStartTime DATETIME,
        @BatchEndTime   DATETIME;

    BEGIN TRY
        SET @BatchStartTime = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Platinum Layer (Aviation Safety DWH)';
        PRINT '================================================';

        /* =====================================================================
           TRUNCATE FACT FIRST, THEN DIMENSIONS
           ===================================================================== */
        PRINT '------------------------------------------------';
        PRINT 'Truncating Platinum Tables';
        PRINT '------------------------------------------------';

        SET @StartTime = GETDATE();

        DELETE FROM platinum.FactIncidents;

        DELETE FROM platinum.DimInvestigationStatus;
        DELETE FROM platinum.DimReportedBy;
        DELETE FROM platinum.DimWeatherCondition;
        DELETE FROM platinum.DimAircraftDamageLevel;
        DELETE FROM platinum.DimPhaseOfFlight;
        DELETE FROM platinum.DimSeverity;
        DELETE FROM platinum.DimEventType;
        DELETE FROM platinum.DimAircraft;
        DELETE FROM platinum.DimOperator;
        DELETE FROM platinum.DimAirport;
        DELETE FROM platinum.DimDate;

        SET @EndTime = GETDATE();
        PRINT '>> Clear Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading Dimension Tables';
        PRINT '------------------------------------------------';

        /* =====================================================================
           Loading platinum.DimDate
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimDate';

        INSERT INTO platinum.DimDate (
            DateKey,
            [Date],
            [Year],
            [Quarter],
            [Month],
            MonthName,
            [Day],
            WeekdayNum,
            WeekdayName
        )
        VALUES (
            -1,
            '1900-01-01',
            1900,
            1,
            1,
            'Unknown',
            1,
            1,
            'Unknown'
        );

        INSERT INTO platinum.DimDate (
            DateKey,
            [Date],
            [Year],
            [Quarter],
            [Month],
            MonthName,
            [Day],
            WeekdayNum,
            WeekdayName
        )
        SELECT
            CONVERT(INT, FORMAT(d.EventDate, 'yyyyMMdd')) AS DateKey,
            d.EventDate AS [Date],
            DATEPART(YEAR, d.EventDate) AS [Year],
            DATEPART(QUARTER, d.EventDate) AS [Quarter],
            DATEPART(MONTH, d.EventDate) AS [Month],
            DATENAME(MONTH, d.EventDate) AS MonthName,
            DATEPART(DAY, d.EventDate) AS [Day],
            DATEPART(WEEKDAY, d.EventDate) AS WeekdayNum,
            DATENAME(WEEKDAY, d.EventDate) AS WeekdayName
        FROM (
            SELECT DISTINCT EventDate
            FROM silver.IncidentReports
            WHERE EventDate IS NOT NULL
        ) d;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimAirport
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimAirport';

        INSERT INTO platinum.DimAirport (
            AirportKey,
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
        VALUES (
            -1,
            'UNKNOWN',
            NULL,
            'Unknown Airport',
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            'Unknown',
            NULL
        );

        INSERT INTO platinum.DimAirport (
            AirportKey,
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
            ROW_NUMBER() OVER (ORDER BY AirportCode) AS AirportKey,
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
        FROM silver.RefAirport;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimOperator
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimOperator';

        INSERT INTO platinum.DimOperator (
            OperatorKey,
            OperatorCode,
            OperatorName,
            OperatorType,
            Country,
            FoundedYear,
            FleetSize,
            Alliance,
            IsActive
        )
        VALUES (
            -1,
            'UNKNOWN',
            'Unknown Operator',
            'Unknown',
            NULL,
            NULL,
            NULL,
            NULL,
            NULL
        );

        INSERT INTO platinum.DimOperator (
            OperatorKey,
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
            ROW_NUMBER() OVER (ORDER BY OperatorCode) AS OperatorKey,
            OperatorCode,
            OperatorName,
            OperatorType,
            Country,
            FoundedYear,
            FleetSize,
            Alliance,
            IsActive
        FROM silver.RefOperator;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimAircraft
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimAircraft';

        INSERT INTO platinum.DimAircraft (
            AircraftKey,
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
        VALUES (
            -1,
            'UNKNOWN',
            NULL,
            'Unknown',
            'Unknown',
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            'Unknown',
            NULL
        );

        INSERT INTO platinum.DimAircraft (
            AircraftKey,
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
            ROW_NUMBER() OVER (ORDER BY AircraftRegistration) AS AircraftKey,
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
        FROM silver.RefAircraft;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimEventType
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimEventType';

        INSERT INTO platinum.DimEventType (
            EventTypeKey,
            EventType
        )
        VALUES (
            -1,
            'Unknown'
        );

        INSERT INTO platinum.DimEventType (
            EventTypeKey,
            EventType
        )
        SELECT
            DENSE_RANK() OVER (ORDER BY EventType) AS EventTypeKey,
            EventType
        FROM (
            SELECT DISTINCT EventType
            FROM silver.IncidentReports
            WHERE EventType IS NOT NULL
        ) x;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimSeverity
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimSeverity';

        INSERT INTO platinum.DimSeverity (
            SeverityKey,
            SeverityLevel
        )
        VALUES (
            -1,
            'Unknown'
        );

        INSERT INTO platinum.DimSeverity (
            SeverityKey,
            SeverityLevel
        )
        SELECT
            DENSE_RANK() OVER (ORDER BY SeverityLevel) AS SeverityKey,
            SeverityLevel
        FROM (
            SELECT DISTINCT SeverityLevel
            FROM silver.IncidentReports
            WHERE SeverityLevel IS NOT NULL
        ) x;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimPhaseOfFlight
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimPhaseOfFlight';

        INSERT INTO platinum.DimPhaseOfFlight (
            PhaseOfFlightKey,
            PhaseOfFlight
        )
        VALUES (
            -1,
            'Unknown'
        );

        INSERT INTO platinum.DimPhaseOfFlight (
            PhaseOfFlightKey,
            PhaseOfFlight
        )
        SELECT
            DENSE_RANK() OVER (ORDER BY PhaseOfFlight) AS PhaseOfFlightKey,
            PhaseOfFlight
        FROM (
            SELECT DISTINCT PhaseOfFlight
            FROM silver.IncidentReports
            WHERE PhaseOfFlight IS NOT NULL
        ) x;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimAircraftDamageLevel
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimAircraftDamageLevel';

        INSERT INTO platinum.DimAircraftDamageLevel (
            AircraftDamageLevelKey,
            AircraftDamageLevel
        )
        VALUES (
            -1,
            'Unknown'
        );

        INSERT INTO platinum.DimAircraftDamageLevel (
            AircraftDamageLevelKey,
            AircraftDamageLevel
        )
        SELECT
            DENSE_RANK() OVER (ORDER BY AircraftDamageLevel) AS AircraftDamageLevelKey,
            AircraftDamageLevel
        FROM (
            SELECT DISTINCT AircraftDamageLevel
            FROM silver.IncidentReports
            WHERE AircraftDamageLevel IS NOT NULL
        ) x;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimWeatherCondition
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimWeatherCondition';

        INSERT INTO platinum.DimWeatherCondition (
            WeatherConditionKey,
            WeatherCondition
        )
        VALUES (
            -1,
            'Unknown'
        );

        INSERT INTO platinum.DimWeatherCondition (
            WeatherConditionKey,
            WeatherCondition
        )
        SELECT
            DENSE_RANK() OVER (ORDER BY WeatherCondition) AS WeatherConditionKey,
            WeatherCondition
        FROM (
            SELECT DISTINCT WeatherCondition
            FROM silver.IncidentReports
            WHERE WeatherCondition IS NOT NULL
        ) x;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimReportedBy
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimReportedBy';

        INSERT INTO platinum.DimReportedBy (
            ReportedByKey,
            ReportedBy
        )
        VALUES (
            -1,
            'Unknown'
        );

        INSERT INTO platinum.DimReportedBy (
            ReportedByKey,
            ReportedBy
        )
        SELECT
            DENSE_RANK() OVER (ORDER BY ReportedBy) AS ReportedByKey,
            ReportedBy
        FROM (
            SELECT DISTINCT ReportedBy
            FROM silver.IncidentReports
            WHERE ReportedBy IS NOT NULL
        ) x;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        /* =====================================================================
           Loading platinum.DimInvestigationStatus
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.DimInvestigationStatus';

        INSERT INTO platinum.DimInvestigationStatus (
            InvestigationStatusKey,
            InvestigationStatus
        )
        VALUES (
            -1,
            'Unknown'
        );

        INSERT INTO platinum.DimInvestigationStatus (
            InvestigationStatusKey,
            InvestigationStatus
        )
        SELECT
            DENSE_RANK() OVER (ORDER BY InvestigationStatus) AS InvestigationStatusKey,
            InvestigationStatus
        FROM (
            SELECT DISTINCT InvestigationStatus
            FROM silver.IncidentReports
            WHERE InvestigationStatus IS NOT NULL
        ) x;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading Fact Table';
        PRINT '------------------------------------------------';

        /* =====================================================================
           Loading platinum.FactIncidents
           ===================================================================== */
        SET @StartTime = GETDATE();
        PRINT '>> Inserting Data Into: platinum.FactIncidents';

        INSERT INTO platinum.FactIncidents (
            IncidentId,
            ReportNumber,
            DateKey,
            AirportKey,
            OperatorKey,
            AircraftKey,
            EventTypeKey,
            SeverityKey,
            PhaseOfFlightKey,
            InjuriesCount,
            FatalitiesCount,
            FlightNumber,
            AircraftDamageLevelKey,
            WeatherConditionKey,
            ReportedByKey,
            InvestigationStatusKey,
            Narrative
        )
        SELECT
            ir.IncidentId,
            ir.ReportNumber,
            COALESCE(dd.DateKey, -1) AS DateKey,
            COALESCE(da.AirportKey, -1) AS AirportKey,
            COALESCE(dop.OperatorKey, -1) AS OperatorKey,
            COALESCE(dac.AircraftKey, -1) AS AircraftKey,
            COALESCE(det.EventTypeKey, -1) AS EventTypeKey,
            COALESCE(dsev.SeverityKey, -1) AS SeverityKey,
            COALESCE(dph.PhaseOfFlightKey, -1) AS PhaseOfFlightKey,
            ir.InjuriesCount,
            ir.FatalitiesCount,
            ir.FlightNumber,
            COALESCE(ddl.AircraftDamageLevelKey, -1) AS AircraftDamageLevelKey,
            COALESCE(dwc.WeatherConditionKey, -1) AS WeatherConditionKey,
            COALESCE(drb.ReportedByKey, -1) AS ReportedByKey,
            COALESCE(dis.InvestigationStatusKey, -1) AS InvestigationStatusKey,
            ir.Narrative
        FROM silver.IncidentReports ir
        LEFT JOIN platinum.DimDate                  dd   ON dd.[date] = ir.EventDate
        LEFT JOIN platinum.DimAirport               da   ON da.AirportCode = ir.AirportCode
        LEFT JOIN platinum.DimOperator              dop  ON dop.OperatorCode = ir.OperatorCode
        LEFT JOIN platinum.DimAircraft              dac  ON dac.AircraftRegistration = ir.AircraftRegistration
        LEFT JOIN platinum.DimEventType            det  ON det.EventType = ir.EventType
        LEFT JOIN platinum.DimSeverity              dsev ON dsev.SeverityLevel = ir.SeverityLevel
        LEFT JOIN platinum.DimPhaseOfFlight       dph  ON dph.PhaseOfFlight = ir.PhaseOfFlight
        LEFT JOIN platinum.DimAircraftDamageLevel ddl  ON ddl.AircraftDamageLevel = ir.AircraftDamageLevel
        LEFT JOIN platinum.DimWeatherCondition     dwc  ON dwc.WeatherCondition = ir.WeatherCondition
        LEFT JOIN platinum.DimReportedBy           drb  ON drb.ReportedBy = ir.ReportedBy
        LEFT JOIN platinum.DimInvestigationStatus  dis  ON dis.InvestigationStatus = ir.InvestigationStatus;

        SET @EndTime = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';


        SET @BatchEndTime = GETDATE();
        PRINT '==========================================';
        PRINT 'Loading Platinum Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @BatchStartTime, @BatchEndTime) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURED DURING LOADING PLATINUM LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
        THROW;
    END CATCH
END
GO