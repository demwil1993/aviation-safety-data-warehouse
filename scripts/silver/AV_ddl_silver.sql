/*
===============================================================================
DDL Script: Create Silver Tables (Aviation Safety DWH)
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables
    if they already exist.

    Silver tables are CLEANSED + TYPED versions of the bronze tables.
    They include a PRIMARY KEY constraint on natural key,
    along with a DwhLoadDate column (DEFAULT SYSDATETIME()).

Note:
    DROP TABLE IF EXISTS Requires SQL Server 2016+ (or Azure SQL)
===============================================================================
*/

-- =========================================================
-- silver.RefOperator
-- =========================================================
DROP TABLE IF EXISTS silver.RefOperator;
GO

CREATE TABLE silver.RefOperator (
    OperatorCode   NVARCHAR(10) NOT NULL,
    OperatorName   NVARCHAR(255) NULL,
    OperatorType   NVARCHAR(50) NULL,
    Country        NVARCHAR(100) NULL,
    FoundedYear    INT NULL,
    FleetSize      INT NULL,
    Alliance       NVARCHAR(50) NULL,
    IsActive       BIT NULL,
    DwhLoadDate    DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_OperatorCode PRIMARY KEY CLUSTERED (OperatorCode)
);
GO

-- =========================================================
-- silver.RefAirport
-- =========================================================
DROP TABLE IF EXISTS silver.RefAirport;
GO

CREATE TABLE silver.RefAirport (
    AirportCode     NVARCHAR(10) NOT NULL,
    IataCode        NVARCHAR(10) NULL,
    AirportName     NVARCHAR(255) NULL,
    City            NVARCHAR(100) NULL,
    StateProvince   NVARCHAR(100) NULL,
    Country         NVARCHAR(100) NULL,
    Region          NVARCHAR(50) NULL,
    Latitude        DECIMAL(9,6) NULL,
    Longitude       DECIMAL(9,6) NULL,
    ElevationFt     INT NULL,
    AirportType     NVARCHAR(50) NULL,
    IsActive        BIT NULL,
    DwhLoadDate     DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_AirportCode PRIMARY KEY CLUSTERED (AirportCode)
);
GO

-- =========================================================
-- silver.RefAircraft
-- =========================================================
DROP TABLE IF EXISTS silver.RefAircraft;
GO

CREATE TABLE silver.RefAircraft (
    AircraftRegistration       NVARCHAR(20) NOT NULL,
    AircraftTypeCode           NVARCHAR(10) NULL,
    Manufacturer               NVARCHAR(100) NULL,
    Model                      NVARCHAR(100) NULL,
    ManufactureYear            INT NULL,
    OperatorCode               NVARCHAR(10) NULL,
    EngineType                 NVARCHAR(50) NULL,
    EngineCount                TINYINT NULL,
    MaxSeatingCapacity         INT NULL,
    AircraftCategory           NVARCHAR(50) NULL,
    IsActive                   BIT NULL,
    DwhLoadDate                DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_AircraftRegistration PRIMARY KEY CLUSTERED (AircraftRegistration)
);
GO

-- =========================================================
-- silver.IncidentReports
-- =========================================================
DROP TABLE IF EXISTS silver.IncidentReports;
GO

CREATE TABLE silver.IncidentReports (
    IncidentId            NVARCHAR(50) NOT NULL,
    ReportNumber          NVARCHAR(50) NULL,
    EventDate             DATE NULL,
    AirportCode           NVARCHAR(10) NULL,
    OperatorCode          NVARCHAR(10) NULL,
    AircraftRegistration  NVARCHAR(20) NULL,
    AircraftTypeCode      NVARCHAR(10) NULL,
    FlightNumber          NVARCHAR(20) NULL,
    PhaseOfFlight         NVARCHAR(50) NULL,
    EventType             NVARCHAR(100) NULL,
    SeverityLevel         NVARCHAR(50) NULL,
    InjuriesCount         INT NULL,
    FatalitiesCount       INT NULL,
    AircraftDamageLevel   NVARCHAR(50) NULL,
    WeatherCondition      NVARCHAR(50) NULL,
    Narrative             NVARCHAR(2000) NULL,
    ReportedBy            NVARCHAR(50) NULL,
    InvestigationStatus   NVARCHAR(50) NULL,
    DwhLoadDate           DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_IncidentId PRIMARY KEY CLUSTERED (IncidentId)
);
GO
