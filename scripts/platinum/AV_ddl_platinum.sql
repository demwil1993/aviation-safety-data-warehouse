/*
===============================================================================
DDL Script: Create Platinum Tables (Aviation Safety DWH)
===============================================================================
Script Purpose:
    This script creates tables in the 'platinum' schema, dropping existing tables
    if they already exist.

    Star Dimension modeling technique is performed.

    Includes foreign key constraints from fact to dimensions 

    Includes seeded -1 "Unknown" members.

Note:
    DROP TABLE IF EXISTS Requires SQL Server 2016+ (or Azure SQL)
===============================================================================
*/

USE AviationSafetyDWH;
GO

-- ============================================================================
-- DROP FACT FIRST, THEN DIMENSIONS
-- ============================================================================
DROP TABLE IF EXISTS platinum.FactIncidents;
DROP TABLE IF EXISTS platinum.DimInvestigationStatus;
DROP TABLE IF EXISTS platinum.DimReportedBy;
DROP TABLE IF EXISTS platinum.DimWeatherCondition;
DROP TABLE IF EXISTS platinum.DimAircraftDamageLevel;
DROP TABLE IF EXISTS platinum.DimPhaseOfFlight;
DROP TABLE IF EXISTS platinum.DimSeverity;
DROP TABLE IF EXISTS platinum.DimEventType;
DROP TABLE IF EXISTS platinum.DimAircraft;
DROP TABLE IF EXISTS platinum.DimOperator;
DROP TABLE IF EXISTS platinum.DimAirport;
DROP TABLE IF EXISTS platinum.DimDate;
GO


-- ============================================================================
-- platinum.DimDate
-- ============================================================================
CREATE TABLE platinum.DimDate (
    DateKey        INT           NOT NULL,
    [Date]         DATE          NOT NULL,
    [Year]         INT           NOT NULL,
    [Quarter]      TINYINT       NOT NULL,
    [Month]        TINYINT       NOT NULL,
    MonthName      VARCHAR(20)   NOT NULL,
    [Day]          TINYINT       NOT NULL,
    WeekdayNum     TINYINT       NOT NULL,
    WeekdayName    VARCHAR(20)   NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (DateKey),
    CONSTRAINT UQ_DimDateDate UNIQUE ([Date])
);
GO

INSERT INTO platinum.DimDate (
    DateKey, [Date], [Year], [Quarter], [Month],
    MonthName, [Day], WeekdayNum, WeekdayName
)
VALUES (
    -1, '1900-01-01', 1900, 1, 1,
    'Unknown', 1, 1, 'Unknown'
);
GO


-- ============================================================================
-- platinum.DimAirport
-- ============================================================================
CREATE TABLE platinum.DimAirport (
    AirportKey      INT             NOT NULL,
    AirportCode     VARCHAR(20)     NOT NULL,
    IataCode        VARCHAR(20)     NULL,
    AirportName     VARCHAR(200)    NOT NULL,
    City            VARCHAR(100)    NULL,
    StateProvince   VARCHAR(100)    NULL,
    Country         VARCHAR(100)    NULL,
    Region          VARCHAR(100)    NULL,
    Latitude        DECIMAL(12,8)   NULL,
    Longitude       DECIMAL(12,8)   NULL,
    ElevationFt     INT             NULL,
    AirportType     VARCHAR(50)     NULL,
    IsActive        BIT             NULL,
    CONSTRAINT PK_DimAirport PRIMARY KEY CLUSTERED (AirportKey),
    CONSTRAINT UQ_DimAirportCode UNIQUE (AirportCode)
);
GO

INSERT INTO platinum.DimAirport (
    AirportKey, AirportCode, IataCode, AirportName, City, StateProvince,
    Country, Region, Latitude, Longitude, ElevationFt, AirportType, IsActive
)
VALUES (
    -1, 'UNKNOWN', NULL, 'Unknown Airport', NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, 'Unknown', NULL
);
GO


-- ============================================================================
-- platinum.DimOperator
-- ============================================================================
CREATE TABLE platinum.DimOperator (
    OperatorKey     INT            NOT NULL,
    OperatorCode    VARCHAR(20)    NOT NULL,
    OperatorName    VARCHAR(200)   NOT NULL,
    OperatorType    VARCHAR(100)   NULL,
    Country         VARCHAR(100)   NULL,
    FoundedYear     INT            NULL,
    FleetSize       INT            NULL,
    Alliance        VARCHAR(100)   NULL,
    IsActive        BIT            NULL,
    CONSTRAINT PK_DimOperator PRIMARY KEY CLUSTERED (OperatorKey),
    CONSTRAINT UQ_DimOperatorCode UNIQUE (OperatorCode)
);
GO

INSERT INTO platinum.DimOperator (
    OperatorKey, OperatorCode, OperatorName, OperatorType,
    Country, FoundedYear, FleetSize, Alliance, IsActive
)
VALUES (
    -1, 'UNKNOWN', 'Unknown Operator', 'Unknown',
    NULL, NULL, NULL, NULL, NULL
);
GO


-- ============================================================================
-- platinum.DimAircraft
-- ============================================================================
CREATE TABLE platinum.DimAircraft (
    AircraftKey            INT            NOT NULL,
    AircraftRegistration   VARCHAR(50)    NOT NULL,
    AircraftTypeCode       VARCHAR(50)    NULL,
    Manufacturer           VARCHAR(100)   NULL,
    Model                  VARCHAR(100)   NULL,
    ManufactureYear        INT            NULL,
    OperatorCode           VARCHAR(20)    NULL,
    EngineType             VARCHAR(50)    NULL,
    EngineCount            INT            NULL,
    MaxSeatingCapacity     INT            NULL,
    AircraftCategory       VARCHAR(50)    NULL,
    IsActive               BIT            NULL,
    CONSTRAINT PK_DimAircraft PRIMARY KEY CLUSTERED (AircraftKey),
    CONSTRAINT UQ_DimAircraftRegistration UNIQUE (AircraftRegistration)
);
GO

INSERT INTO platinum.DimAircraft (
    AircraftKey, AircraftRegistration, AircraftTypeCode, Manufacturer,
    Model, ManufactureYear, OperatorCode, EngineType, EngineCount,
    MaxSeatingCapacity, AircraftCategory, IsActive
)
VALUES (
    -1, 'UNKNOWN', NULL, 'Unknown',
    'Unknown', NULL, NULL, NULL, NULL,
    NULL, 'Unknown', NULL
);
GO


-- ============================================================================
-- platinum.DimEventType
-- ============================================================================
CREATE TABLE platinum.DimEventType (
    EventTypeKey    INT            NOT NULL,
    EventType       VARCHAR(100)   NOT NULL,
    CONSTRAINT PK_DimEventType PRIMARY KEY CLUSTERED (EventTypeKey),
    CONSTRAINT UQ_dimEventType UNIQUE (EventType)
);
GO

INSERT INTO platinum.DimEventType (EventTypeKey, EventType)
VALUES (-1, 'Unknown');
GO


-- ============================================================================
-- platinum.DimSeverity
-- ============================================================================
CREATE TABLE platinum.DimSeverity (
    SeverityKey     INT            NOT NULL,
    SeverityLevel   VARCHAR(50)    NOT NULL,
    CONSTRAINT PK_DimSeverity PRIMARY KEY CLUSTERED (SeverityKey),
    CONSTRAINT UQ_DimSeverity UNIQUE (SeverityLevel)
);
GO

INSERT INTO platinum.DimSeverity (SeverityKey, SeverityLevel)
VALUES (-1, 'Unknown');
GO


-- ============================================================================
-- platinum.DimPhaseOfFlight
-- ============================================================================
CREATE TABLE platinum.DimPhaseOfFlight (
    PhaseOfFlightKey    INT            NOT NULL,
    PhaseOfFlight       VARCHAR(100)   NOT NULL,
    CONSTRAINT PK_DimPhaseOfFlight PRIMARY KEY CLUSTERED (PhaseOfFlightKey),
    CONSTRAINT UQ_DimPhaseOfFlight UNIQUE (PhaseOfFlight)
);
GO

INSERT INTO platinum.DimPhaseOfFlight (PhaseOfFlightKey, PhaseOfFlight)
VALUES (-1, 'Unknown');
GO


-- ============================================================================
-- platinum.DimAircraftDamageLevel
-- ============================================================================
CREATE TABLE platinum.DimAircraftDamageLevel (
    AircraftDamageLevelKey    INT           NOT NULL,
    AircraftDamageLevel       VARCHAR(50)   NOT NULL,
    CONSTRAINT PK_DimAircraftDamageLevel PRIMARY KEY CLUSTERED (AircraftDamageLevelKey),
    CONSTRAINT UQ_DimAircraftDamageLevel UNIQUE (AircraftDamageLevel)
);
GO

INSERT INTO platinum.DimAircraftDamageLevel (
    AircraftDamageLevelKey, AircraftDamageLevel
)
VALUES (-1, 'Unknown');
GO


-- ============================================================================
-- platinum.DimWeatherCondition
-- ============================================================================
CREATE TABLE platinum.DimWeatherCondition (
    WeatherConditionKey    INT           NOT NULL,
    WeatherCondition       VARCHAR(50)   NOT NULL,
    CONSTRAINT PK_DimWeatherCondition PRIMARY KEY CLUSTERED (WeatherConditionKey),
    CONSTRAINT UQ_DimWeatherCondition UNIQUE (WeatherCondition)
);
GO

INSERT INTO platinum.DimWeatherCondition (
    WeatherConditionKey, WeatherCondition
)
VALUES (-1, 'Unknown');
GO


-- ============================================================================
-- platinum.DimReportedBy
-- ============================================================================
CREATE TABLE platinum.DimReportedBy (
    ReportedByKey    INT            NOT NULL,
    ReportedBy       VARCHAR(100)   NOT NULL,
    CONSTRAINT PK_DimReportedBy PRIMARY KEY CLUSTERED (ReportedByKey),
    CONSTRAINT UQ_DimReportedBy UNIQUE (ReportedBy)
);
GO

INSERT INTO platinum.DimReportedBy (ReportedByKey, ReportedBy)
VALUES (-1, 'Unknown');
GO


-- ============================================================================
-- platinum.DimInvestigationStatus
-- ============================================================================
CREATE TABLE platinum.DimInvestigationStatus (
    InvestigationStatusKey    INT            NOT NULL,
    InvestigationStatus       VARCHAR(100)   NOT NULL,
    CONSTRAINT PK_DimInvestigationStatus PRIMARY KEY CLUSTERED (InvestigationStatusKey),
    CONSTRAINT UQ_DimInvestigationStatus UNIQUE (InvestigationStatus)
);
GO

INSERT INTO platinum.DimInvestigationStatus (
    InvestigationStatusKey, InvestigationStatus
)
VALUES (-1, 'Unknown');
GO


-- ============================================================================
-- platinum.FactIncidents
-- ============================================================================
CREATE TABLE platinum.FactIncidents (
    IncidentId                  VARCHAR(50)    NOT NULL,
    ReportNumber                VARCHAR(50)    NULL,
    DateKey                     INT            NOT NULL CONSTRAINT Df_FactIncidents_DateKey DEFAULT (-1),
    AirportKey                  INT            NOT NULL CONSTRAINT Df_FactIncidents_AirportKey DEFAULT (-1),
    OperatorKey                 INT            NOT NULL CONSTRAINT Df_FactIncidents_OperatorKey DEFAULT (-1),
    AircraftKey                 INT            NOT NULL CONSTRAINT Df_FactIncidents_AircraftKey DEFAULT (-1),
    EventTypeKey                INT            NOT NULL CONSTRAINT Df_FactIncidents_EventTypeKey DEFAULT (-1),
    SeverityKey                 INT            NOT NULL CONSTRAINT Df_FactIncidents_SeverityKey DEFAULT (-1),
    PhaseOfFlightKey            INT            NOT NULL CONSTRAINT Df_FactIncidents_phase_key DEFAULT (-1),
    InjuriesCount               INT            NULL,
    FatalitiesCount             INT            NULL,
    FlightNumber                VARCHAR(50)    NULL,
    AircraftDamageLevelKey      INT            NOT NULL CONSTRAINT Df_FactIncidents_DamageKey DEFAULT (-1),
    WeatherConditionKey         INT            NOT NULL CONSTRAINT Df_FactIncidents_WeatherKey DEFAULT (-1),
    ReportedByKey               INT            NOT NULL CONSTRAINT Df_FactIncidents_ReportedByKey DEFAULT (-1),
    InvestigationStatusKey      INT            NOT NULL CONSTRAINT Df_FactIncidents_StatusKey DEFAULT (-1),
    Narrative                   VARCHAR(MAX)   NULL,

    CONSTRAINT PK_FactIncidents PRIMARY KEY CLUSTERED (IncidentId),

    CONSTRAINT FK_FactIncidentsDimDate 
        FOREIGN KEY (DateKey)
        REFERENCES platinum.DimDate(DateKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimAirport 
        FOREIGN KEY (AirportKey)
        REFERENCES platinum.DimAirport(AirportKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimOperator
        FOREIGN KEY (OperatorKey)
        REFERENCES platinum.DimOperator(OperatorKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimAircraft
        FOREIGN KEY (AircraftKey)
        REFERENCES platinum.DimAircraft(AircraftKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimEventType
        FOREIGN KEY (EventTypeKey)
        REFERENCES platinum.DimEventType(EventTypeKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimSeverity
        FOREIGN KEY (SeverityKey)
        REFERENCES platinum.DimSeverity(SeverityKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimPhaseOfFlight
        FOREIGN KEY (PhaseOfFlightKey)
        REFERENCES platinum.DimPhaseOfFlight(PhaseOfFlightKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimAircraftDamageLevel
        FOREIGN KEY (AircraftDamageLevelKey)
        REFERENCES platinum.DimAircraftDamageLevel(AircraftDamageLevelKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidensDimWeatherCondition
        FOREIGN KEY (WeatherConditionKey)
        REFERENCES platinum.DimWeatherCondition(WeatherConditionKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimReportedBy
        FOREIGN KEY (ReportedByKey)
        REFERENCES platinum.DimReportedBy(ReportedByKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_FactIncidentsDimInvestigationStatus
        FOREIGN KEY (InvestigationStatusKey)
        REFERENCES platinum.DimInvestigationStatus(InvestigationStatusKey)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO