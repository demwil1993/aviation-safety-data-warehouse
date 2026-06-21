/*
===================================================================================
DDL Script: Create Bronze Tables (Aviation Safety DWH)
===================================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables
    if they already exist.

    Bronze tables are RAW ingestions from CSV and JSON files, and are 
    intentionally permissive (mostly NVARCHAR) to tolerate messy source 
    values (blanks, "N/A", bad dates).

Note:
    DROP TABLE IF EXISTS Requires SQL Server 2016+ (or Azure SQL)
===================================================================================
*/

USE AviationSafetyDWH;
GO

-- =========================
-- bronze.ref_operator
-- =========================
DROP TABLE IF EXISTS bronze.ref_operator;
GO

CREATE TABLE bronze.ref_operator (
    operator_code   NVARCHAR(50),
    operator_name   NVARCHAR(255),
    operator_type   NVARCHAR(50),
    country         NVARCHAR(100),
    founded_year    NVARCHAR(50),
    fleet_size      NVARCHAR(50),
    alliance        NVARCHAR(50),
    is_active       NVARCHAR(10),
    created_at      NVARCHAR(50)
);
GO


-- =========================
-- bronze.ref_airport
-- =========================
DROP TABLE IF EXISTS bronze.ref_airport;
GO

CREATE TABLE bronze.ref_airport (
    airport_code     NVARCHAR(50),
    iata_code        NVARCHAR(50),
    airport_name     NVARCHAR(255),
    city             NVARCHAR(100),
    state_province   NVARCHAR(100),
    country          NVARCHAR(100),
    region           NVARCHAR(50),
    latitude         NVARCHAR(50),
    longitude        NVARCHAR(50),
    elevation_ft     NVARCHAR(50),
    airport_type     NVARCHAR(50),
    is_active        NVARCHAR(10),
    created_at       NVARCHAR(50)
);
GO


-- =========================
-- bronze.ref_aircraft
-- =========================
DROP TABLE IF EXISTS bronze.ref_aircraft;
GO

CREATE TABLE bronze.ref_aircraft (
    aircraft_registration   NVARCHAR(50),
    aircraft_type_code      NVARCHAR(50),
    manufacturer            NVARCHAR(100),
    model                   NVARCHAR(100),
    manufacture_year        NVARCHAR(50),
    operator_code           NVARCHAR(50),
    engine_type             NVARCHAR(50),
    engine_count            NVARCHAR(50),
    max_seating_capacity    NVARCHAR(50),
    aircraft_category       NVARCHAR(50),
    is_active               NVARCHAR(10),
    created_at              NVARCHAR(50)
);
GO


-- =========================
-- bronze.incident_reports
-- =========================
DROP TABLE IF EXISTS bronze.incident_reports;
GO

CREATE TABLE bronze.incident_reports (
    incident_id            NVARCHAR(50),
    report_number          NVARCHAR(50),
    event_datetime         NVARCHAR(50),
    airport_code           NVARCHAR(50),
    operator_code          NVARCHAR(50),
    aircraft_registration  NVARCHAR(50),
    aircraft_type_code     NVARCHAR(50),
    flight_number          NVARCHAR(50),
    phase_of_flight        NVARCHAR(50),
    event_type             NVARCHAR(100),
    severity_level         NVARCHAR(50),
    injuries_count         NVARCHAR(50),
    fatalities_count       NVARCHAR(50),
    aircraft_damage_level  NVARCHAR(50),
    weather_condition      NVARCHAR(50),
    narrative              NVARCHAR(2000),
    reported_by            NVARCHAR(50),
    investigation_status   NVARCHAR(50),
    created_at             NVARCHAR(50)
);
GO
