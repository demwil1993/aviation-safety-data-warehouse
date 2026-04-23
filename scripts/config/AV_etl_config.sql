/*
===============================================================================
Configuration Table for ETL File Paths - Aviation Safety DWH
===============================================================================
Purpose:
    Stores external file locations outside of ETL procedure code.
    Update config_value rows when file locations change.
===============================================================================
*/

IF OBJECT_ID('config.EtlConfig', 'U') IS NULL
BEGIN
    CREATE TABLE config.EtlConfig (
        ConfigKey   VARCHAR(100)  NOT NULL PRIMARY KEY,
        ConfigValue NVARCHAR(1000) NOT NULL
    );
END
GO

MERGE config.EtlConfig AS target
USING (VALUES
    ('RefOperatorPath',     'C:\Users\aspar\Desktop\DW_Project\data\ref_operator.json'),
    ('RefAirportPath',      'C:\Users\aspar\Desktop\DW_Project\data\ref_airport.json'),
    ('RefAircraftPath',     'C:\Users\aspar\Desktop\DW_Project\data\ref_aircraft.json'),
    ('IncidentReportsPath', 'C:\Users\aspar\Desktop\DW_Project\data\incident_reports.csv')
) AS source (ConfigKey, ConfigValue)
    ON target.ConfigKey = source.ConfigKey
WHEN MATCHED THEN
    UPDATE SET target.ConfigValue = source.ConfigValue
WHEN NOT MATCHED THEN
    INSERT (ConfigKey, ConfigValue)
    VALUES (source.ConfigKey, source.ConfigValue);
GO
