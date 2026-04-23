/*
===============================================================================
DDL Script: Create Gold Layer Views (Aviation Safety DWH)
===============================================================================
Notes
- Gold layer is business-ready views built from the Platinum layer
- Updated to PascalCase to align with Platinum table and column names
- Duplicate Aircraft risk view definition removed
===============================================================================
*/

CREATE OR ALTER VIEW gold.VW_IncidentDetail AS
SELECT
    /* ---------------------------
       Incident identifiers
    ---------------------------- */
    f.IncidentId,
    f.ReportNumber,
    f.FlightNumber,

    /* ---------------------------
       Date attributes
    ---------------------------- */
    f.DateKey,
    d.[Date]                    AS IncidentDate,
    d.[Year]                    AS IncidentYear,
    d.[Quarter]                 AS IncidentQuarter,
    d.[Month]                   AS IncidentMonth,
    d.MonthName                 AS IncidentMonthName,
    d.[Day]                     AS IncidentDay,
    d.WeekdayNum                AS IncidentWeekdayNum,
    d.WeekdayName               AS IncidentWeekdayName,

    /* ---------------------------
       Airport attributes
    ---------------------------- */
    f.AirportKey,
    ap.AirportCode,
    ap.IataCode,
    ap.AirportName,
    ap.City                     AS AirportCity,
    ap.StateProvince            AS AirportStateProvince,
    ap.Country                  AS AirportCountry,
    ap.Region                   AS AirportRegion,
    ap.Latitude                 AS AirportLatitude,
    ap.Longitude                AS AirportLongitude,
    ap.ElevationFt              AS AirportElevationFt,
    ap.AirportType,
    ap.IsActive                 AS AirportIsActive,

    /* ---------------------------
       Operator attributes
    ---------------------------- */
    f.OperatorKey,
    op.OperatorCode,
    op.OperatorName,
    op.OperatorType,
    op.Country                  AS OperatorCountry,
    op.FoundedYear              AS OperatorFoundedYear,
    op.FleetSize                AS OperatorFleetSize,
    op.Alliance                 AS OperatorAlliance,
    op.IsActive                 AS OperatorIsActive,

    /* ---------------------------
       Aircraft attributes
    ---------------------------- */
    f.AircraftKey,
    ac.AircraftRegistration,
    ac.AircraftTypeCode,
    ac.Manufacturer             AS AircraftManufacturer,
    ac.Model                    AS AircraftModel,
    ac.ManufactureYear          AS AircraftManufactureYear,
    ac.EngineType               AS AircraftEngineType,
    ac.EngineCount              AS AircraftEngineCount,
    ac.MaxSeatingCapacity       AS AircraftMaxSeatingCapacity,
    ac.AircraftCategory,
    ac.IsActive                 AS AircraftIsActive,

    /* ---------------------------
       Classification dimensions
    ---------------------------- */
    f.EventTypeKey,
    et.EventType,

    f.SeverityKey,
    sv.SeverityLevel,

    f.PhaseOfFlightKey,
    pf.PhaseOfFlight,

    f.AircraftDamageLevelKey,
    adl.AircraftDamageLevel,

    f.WeatherConditionKey,
    wc.WeatherCondition,

    f.ReportedByKey,
    rb.ReportedBy,

    f.InvestigationStatusKey,
    ist.InvestigationStatus,

    /* ---------------------------
       Measures
    ---------------------------- */
    f.InjuriesCount,
    f.FatalitiesCount,

    /* ---------------------------
       Helpful derived metrics
    ---------------------------- */
    CASE
        WHEN ISNULL(f.InjuriesCount, 0) > 0 THEN 1
        ELSE 0
    END AS HasInjuriesFlag,

    CASE
        WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
        ELSE 0
    END AS HasFatalitiesFlag,

    CASE
        WHEN ISNULL(f.InjuriesCount, 0) > 0
          OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
        ELSE 0
    END AS HasCasualtiesFlag,

    ISNULL(f.InjuriesCount, 0) + ISNULL(f.FatalitiesCount, 0) AS TotalCasualtiesCount,

    /* ---------------------------
       Narrative
    ---------------------------- */
    f.Narrative

FROM platinum.FactIncidents f
LEFT JOIN platinum.DimDate d
    ON f.DateKey = d.DateKey
LEFT JOIN platinum.DimAirport ap
    ON f.AirportKey = ap.AirportKey
LEFT JOIN platinum.DimOperator op
    ON f.OperatorKey = op.OperatorKey
LEFT JOIN platinum.DimAircraft ac
    ON f.AircraftKey = ac.AircraftKey
LEFT JOIN platinum.DimEventType et
    ON f.EventTypeKey = et.EventTypeKey
LEFT JOIN platinum.DimSeverity sv
    ON f.SeverityKey = sv.SeverityKey
LEFT JOIN platinum.DimPhaseOfFlight pf
    ON f.PhaseOfFlightKey = pf.PhaseOfFlightKey
LEFT JOIN platinum.DimAircraftDamageLevel adl
    ON f.AircraftDamageLevelKey = adl.AircraftDamageLevelKey
LEFT JOIN platinum.DimWeatherCondition wc
    ON f.WeatherConditionKey = wc.WeatherConditionKey
LEFT JOIN platinum.DimReportedBy rb
    ON f.ReportedByKey = rb.ReportedByKey
LEFT JOIN platinum.DimInvestigationStatus ist
    ON f.InvestigationStatusKey = ist.InvestigationStatusKey;
GO


CREATE OR ALTER VIEW gold.VW_OperatorSafety AS
SELECT
    /* ---------------------------
       Year grain
    ---------------------------- */
    d.[Year] AS IncidentYear,

    /* ---------------------------
       Operator
    ---------------------------- */
    f.OperatorKey,
    op.OperatorCode,
    CASE
        WHEN op.OperatorName = 'Unknown Operator' THEN NULL
        ELSE op.OperatorName
    END AS OperatorName,
    op.OperatorType,
    op.Country AS OperatorCountry,
    op.Alliance,
    op.IsActive AS OperatorIsActive,

    /* ---------------------------
       Core metrics
    ---------------------------- */
    COUNT(*) AS IncidentCount,
    SUM(ISNULL(f.InjuriesCount, 0)) AS TotalInjuries,
    SUM(ISNULL(f.FatalitiesCount, 0)) AS TotalFatalities,
    SUM(ISNULL(f.InjuriesCount, 0) + ISNULL(f.FatalitiesCount, 0)) AS TotalCasualties,

    /* ---------------------------
       Incident flags
    ---------------------------- */
    SUM(CASE WHEN ISNULL(f.InjuriesCount, 0) > 0 THEN 1 ELSE 0 END) AS InjuryIncidentCount,
    SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END) AS FatalIncidentCount,
    SUM(CASE
            WHEN ISNULL(f.InjuriesCount, 0) > 0
              OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
            ELSE 0
        END) AS CasualtyIncidentCount,

    /* ---------------------------
       Severity normalization
    ---------------------------- */
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'LOW' THEN 1 ELSE 0 END) AS LowSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'MEDIUM' THEN 1 ELSE 0 END) AS MediumSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'HIGH' THEN 1 ELSE 0 END) AS HighSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'CRITICAL' THEN 1 ELSE 0 END) AS CriticalSeverityIncidentCount,
    SUM(CASE WHEN sv.SeverityLevel = 'Unknown' OR sv.SeverityLevel IS NULL THEN 1 ELSE 0 END) AS UnknownSeverityIncidentCount,

    /* ---------------------------
       Rates
    ---------------------------- */
    CAST(
        1.0 * SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS FatalIncidentRate,

    CAST(
        1.0 * SUM(CASE
                    WHEN ISNULL(f.InjuriesCount, 0) > 0
                      OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
                    ELSE 0
                  END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS CasualtyIncidentRate

FROM platinum.FactIncidents f
LEFT JOIN platinum.DimDate d
    ON f.DateKey = d.DateKey
LEFT JOIN platinum.DimOperator op
    ON f.OperatorKey = op.OperatorKey
LEFT JOIN platinum.DimSeverity sv
    ON f.SeverityKey = sv.SeverityKey
GROUP BY
    d.[Year],
    f.OperatorKey,
    op.OperatorCode,
    CASE
        WHEN op.OperatorName = 'Unknown Operator' THEN NULL
        ELSE op.OperatorName
    END,
    op.OperatorType,
    op.Country,
    op.Alliance,
    op.IsActive;
GO


CREATE OR ALTER VIEW gold.VwAirportRisk AS
SELECT
    /* ---------------------------
       Year grain
    ---------------------------- */
    d.[Year] AS IncidentYear,

    /* ---------------------------
       Airport
    ---------------------------- */
    f.AirportKey,
    ap.AirportCode,
    ap.IataCode,
    CASE
        WHEN ap.AirportName = 'Unknown Airport' THEN NULL
        ELSE ap.AirportName
    END AS AirportName,
    ap.City AS AirportCity,
    ap.StateProvince AS AirportStateProvince,
    ap.Country AS AirportCountry,
    ap.Region AS AirportRegion,
    ap.AirportType,
    ap.IsActive AS AirportIsActive,

    /* ---------------------------
       Core metrics
    ---------------------------- */
    COUNT(*) AS IncidentCount,
    SUM(ISNULL(f.InjuriesCount, 0)) AS TotalInjuries,
    SUM(ISNULL(f.FatalitiesCount, 0)) AS TotalFatalities,
    SUM(ISNULL(f.InjuriesCount, 0) + ISNULL(f.FatalitiesCount, 0)) AS TotalCasualties,

    /* ---------------------------
       Incident flags
    ---------------------------- */
    SUM(CASE WHEN ISNULL(f.InjuriesCount, 0) > 0 THEN 1 ELSE 0 END) AS InjuryIncidentCount,
    SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END) AS FatalIncidentCount,
    SUM(CASE
            WHEN ISNULL(f.InjuriesCount, 0) > 0
              OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
            ELSE 0
        END) AS CasualtyIncidentCount,

    /* ---------------------------
       Severity mix
    ---------------------------- */
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'LOW' THEN 1 ELSE 0 END) AS LowSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'MEDIUM' THEN 1 ELSE 0 END) AS MediumSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'HIGH' THEN 1 ELSE 0 END) AS HighSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'CRITICAL' THEN 1 ELSE 0 END) AS CriticalSeverityIncidentCount,
    SUM(CASE WHEN sv.SeverityLevel = 'Unknown' OR sv.SeverityLevel IS NULL THEN 1 ELSE 0 END) AS UnknownSeverityIncidentCount,

    /* ---------------------------
       Rate metrics
    ---------------------------- */
    CAST(
        1.0 * SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS FatalIncidentRate,

    CAST(
        1.0 * SUM(CASE
                    WHEN ISNULL(f.InjuriesCount, 0) > 0
                      OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
                    ELSE 0
                  END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS CasualtyIncidentRate

FROM platinum.FactIncidents f
LEFT JOIN platinum.DimDate d
    ON f.DateKey = d.DateKey
LEFT JOIN platinum.DimAirport ap
    ON f.AirportKey = ap.AirportKey
LEFT JOIN platinum.DimSeverity sv
    ON f.SeverityKey = sv.SeverityKey
GROUP BY
    d.[Year],
    f.AirportKey,
    ap.AirportCode,
    ap.IataCode,
    CASE
        WHEN ap.AirportName = 'Unknown Airport' THEN NULL
        ELSE ap.AirportName
    END,
    ap.City,
    ap.StateProvince,
    ap.Country,
    ap.Region,
    ap.AirportType,
    ap.IsActive;
GO


CREATE OR ALTER VIEW gold.VW_PhaseOfFlightRisk AS
SELECT
    /* ---------------------------
       Year grain
    ---------------------------- */
    d.[Year] AS IncidentYear,

    /* ---------------------------
       Phase of flight
    ---------------------------- */
    f.PhaseOfFlightKey,
    CASE
        WHEN pf.PhaseOfFlight = 'Unknown' THEN NULL
        ELSE pf.PhaseOfFlight
    END AS PhaseOfFlight,

    /* ---------------------------
       Core metrics
    ---------------------------- */
    COUNT(*) AS IncidentCount,
    SUM(ISNULL(f.InjuriesCount, 0)) AS TotalInjuries,
    SUM(ISNULL(f.FatalitiesCount, 0)) AS TotalFatalities,
    SUM(ISNULL(f.InjuriesCount, 0) + ISNULL(f.FatalitiesCount, 0)) AS TotalCasualties,

    /* ---------------------------
       Incident flags
    ---------------------------- */
    SUM(CASE WHEN ISNULL(f.InjuriesCount, 0) > 0 THEN 1 ELSE 0 END) AS InjuryIncidentCount,
    SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END) AS FatalIncidentCount,
    SUM(CASE
            WHEN ISNULL(f.InjuriesCount, 0) > 0
              OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
            ELSE 0
        END) AS CasualtyIncidentCount,

    /* ---------------------------
       Severity mix
    ---------------------------- */
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'LOW' THEN 1 ELSE 0 END) AS LowSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'MEDIUM' THEN 1 ELSE 0 END) AS MediumSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'HIGH' THEN 1 ELSE 0 END) AS HighSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'CRITICAL' THEN 1 ELSE 0 END) AS CriticalSeverityIncidentCount,
    SUM(CASE WHEN sv.SeverityLevel = 'Unknown' OR sv.SeverityLevel IS NULL THEN 1 ELSE 0 END) AS UnknownSeverityIncidentCount,

    /* ---------------------------
       Rate metrics
    ---------------------------- */
    CAST(
        1.0 * SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS FatalIncidentRate,

    CAST(
        1.0 * SUM(CASE
                    WHEN ISNULL(f.InjuriesCount, 0) > 0
                      OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
                    ELSE 0
                  END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS CasualtyIncidentRate

FROM platinum.FactIncidents f
LEFT JOIN platinum.DimDate d
    ON f.DateKey = d.DateKey
LEFT JOIN platinum.DimPhaseOfFlight pf
    ON f.PhaseOfFlightKey = pf.PhaseOfFlightKey
LEFT JOIN platinum.DimSeverity sv
    ON f.SeverityKey = sv.SeverityKey
GROUP BY
    d.[Year],
    f.PhaseOfFlightKey,
    CASE
        WHEN pf.PhaseOfFlight = 'Unknown' THEN NULL
        ELSE pf.PhaseOfFlight
    END;
GO


CREATE OR ALTER VIEW gold.VW_WeatherImpact AS
SELECT
    /* ---------------------------
       Year grain
    ---------------------------- */
    d.[Year] AS IncidentYear,

    /* ---------------------------
       Weather condition
    ---------------------------- */
    f.WeatherConditionKey,
    CASE
        WHEN wc.WeatherCondition = 'Unknown' THEN NULL
        ELSE wc.WeatherCondition
    END AS WeatherCondition,

    /* ---------------------------
       Core metrics
    ---------------------------- */
    COUNT(*) AS IncidentCount,
    SUM(ISNULL(f.InjuriesCount, 0)) AS TotalInjuries,
    SUM(ISNULL(f.FatalitiesCount, 0)) AS TotalFatalities,
    SUM(ISNULL(f.InjuriesCount, 0) + ISNULL(f.FatalitiesCount, 0)) AS TotalCasualties,

    /* ---------------------------
       Incident flags
    ---------------------------- */
    SUM(CASE WHEN ISNULL(f.InjuriesCount, 0) > 0 THEN 1 ELSE 0 END) AS InjuryIncidentCount,
    SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END) AS FatalIncidentCount,
    SUM(CASE
            WHEN ISNULL(f.InjuriesCount, 0) > 0
              OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
            ELSE 0
        END) AS CasualtyIncidentCount,

    /* ---------------------------
       Severity mix
    ---------------------------- */
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'LOW' THEN 1 ELSE 0 END) AS LowSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'MEDIUM' THEN 1 ELSE 0 END) AS MediumSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'HIGH' THEN 1 ELSE 0 END) AS HighSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'CRITICAL' THEN 1 ELSE 0 END) AS CriticalSeverityIncidentCount,
    SUM(CASE WHEN sv.SeverityLevel = 'Unknown' OR sv.SeverityLevel IS NULL THEN 1 ELSE 0 END) AS UnknownSeverityIncidentCount,

    /* ---------------------------
       Rate metrics
    ---------------------------- */
    CAST(
        1.0 * SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS FatalIncidentRate,

    CAST(
        1.0 * SUM(CASE
                    WHEN ISNULL(f.InjuriesCount, 0) > 0
                      OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
                    ELSE 0
                  END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS CasualtyIncidentRate

FROM platinum.FactIncidents f
LEFT JOIN platinum.DimDate d
    ON f.DateKey = d.DateKey
LEFT JOIN platinum.DimWeatherCondition wc
    ON f.WeatherConditionKey = wc.WeatherConditionKey
LEFT JOIN platinum.DimSeverity sv
    ON f.SeverityKey = sv.SeverityKey
GROUP BY
    d.[Year],
    f.WeatherConditionKey,
    CASE
        WHEN wc.WeatherCondition = 'Unknown' THEN NULL
        ELSE wc.WeatherCondition
    END;
GO


CREATE OR ALTER VIEW gold.VW_AircraftRisk AS
SELECT
    /* ---------------------------
       Year grain
    ---------------------------- */
    d.[Year] AS IncidentYear,

    /* ---------------------------
       Aircraft
    ---------------------------- */
    f.AircraftKey,
    ac.AircraftRegistration,
    ac.AircraftTypeCode,
    CASE
        WHEN ac.Manufacturer = 'Unknown' THEN NULL
        ELSE ac.Manufacturer
    END AS AircraftManufacturer,
    CASE
        WHEN ac.Model = 'Unknown' THEN NULL
        ELSE ac.Model
    END AS AircraftModel,
    ac.ManufactureYear AS AircraftManufactureYear,
    ac.EngineType AS AircraftEngineType,
    ac.EngineCount AS AircraftEngineCount,
    ac.MaxSeatingCapacity AS AircraftMaxSeatingCapacity,
    ac.AircraftCategory,
    ac.IsActive AS AircraftIsActive,

    /* ---------------------------
       Core metrics
    ---------------------------- */
    COUNT(*) AS IncidentCount,
    SUM(ISNULL(f.InjuriesCount, 0)) AS TotalInjuries,
    SUM(ISNULL(f.FatalitiesCount, 0)) AS TotalFatalities,
    SUM(ISNULL(f.InjuriesCount, 0) + ISNULL(f.FatalitiesCount, 0)) AS TotalCasualties,

    /* ---------------------------
       Incident flags
    ---------------------------- */
    SUM(CASE WHEN ISNULL(f.InjuriesCount, 0) > 0 THEN 1 ELSE 0 END) AS InjuryIncidentCount,
    SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END) AS FatalIncidentCount,
    SUM(CASE
            WHEN ISNULL(f.InjuriesCount, 0) > 0
              OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
            ELSE 0
        END) AS CasualtyIncidentCount,

    /* ---------------------------
       Severity mix
    ---------------------------- */
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'LOW' THEN 1 ELSE 0 END) AS LowSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'MEDIUM' THEN 1 ELSE 0 END) AS MediumSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'HIGH' THEN 1 ELSE 0 END) AS HighSeverityIncidentCount,
    SUM(CASE WHEN UPPER(sv.SeverityLevel) = 'CRITICAL' THEN 1 ELSE 0 END) AS CriticalSeverityIncidentCount,
    SUM(CASE WHEN sv.SeverityLevel = 'Unknown' OR sv.SeverityLevel IS NULL THEN 1 ELSE 0 END) AS UnknownSeverityIncidentCount,

    /* ---------------------------
       Rate metrics
    ---------------------------- */
    CAST(
        1.0 * SUM(CASE WHEN ISNULL(f.FatalitiesCount, 0) > 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS FatalIncidentRate,

    CAST(
        1.0 * SUM(CASE
                    WHEN ISNULL(f.InjuriesCount, 0) > 0
                      OR ISNULL(f.FatalitiesCount, 0) > 0 THEN 1
                    ELSE 0
                  END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS CasualtyIncidentRate

FROM platinum.FactIncidents f
LEFT JOIN platinum.DimDate d
    ON f.DateKey = d.DateKey
LEFT JOIN platinum.DimAircraft ac
    ON f.AircraftKey = ac.AircraftKey
LEFT JOIN platinum.DimSeverity sv
    ON f.SeverityKey = sv.SeverityKey
GROUP BY
    d.[Year],
    f.AircraftKey,
    ac.AircraftRegistration,
    ac.AircraftTypeCode,
    CASE
        WHEN ac.Manufacturer = 'Unknown' THEN NULL
        ELSE ac.Manufacturer
    END,
    CASE
        WHEN ac.Model = 'Unknown' THEN NULL
        ELSE ac.Model
    END,
    ac.ManufactureYear,
    ac.EngineType,
    ac.EngineCount,
    ac.MaxSeatingCapacity,
    ac.AircraftCategory,
    ac.IsActive;
GO
