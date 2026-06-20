/*
================================================================================
Create Database and Schemas
================================================================================
Creates AviationSafetyDWH with schemas: bronze, silver, platinum, gold, & config
WARNING: Drops and recreates the database.
================================================================================
*/
USE master;
GO

IF DB_ID('AviationSafetyDWH') IS NOT NULL
BEGIN
    ALTER DATABASE AviationSafetyDWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AviationSafetyDWH;
END
GO

CREATE DATABASE AviationSafetyDWH;
GO

USE AviationSafetyDWH;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')     EXEC('CREATE SCHEMA bronze');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')     EXEC('CREATE SCHEMA silver');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'platinum')   EXEC('CREATE SCHEMA platinum');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')       EXEC('CREATE SCHEMA gold');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'config')     EXEC('CREATE SCHEMA config');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'etl')        EXEC('CREATE SCHEMA etl');
GO