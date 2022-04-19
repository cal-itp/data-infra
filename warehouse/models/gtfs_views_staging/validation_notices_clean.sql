{{ config(materialized='table') }}

WITH validation_notices AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'validation_notices') }}
),

validation_notices_clean AS (

    -- Must trim string fields that come from raw GTFS tables that we clean & load into views
    -- (To allow joining with the cleaned data after this is run)
    -- This table has over 70 columns, so even though EXCEPT is a bit messy it still seems cleaner

    SELECT
        * EXCEPT(
            calitp_deleted_at,
            fareId,
            previousFareId,
            shapeId,
            routeId,
            currentDate,
            feedEndDate,
            routeColor,
            routeTextColor,
            tripId,
            tripIdA,
            tripIdB,
            routeShortName,
            routeLongName,
            routeDesc,
            stopId,
            stopName,
            serviceIdA,
            serviceIdB,
            departureTime,
            arrivalTime,
            parentStation,
            parentStopName),
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at,
        TRIM(fareId) AS fareId,
        TRIM(previousFareId) AS previousFareId,
        TRIM(shapeId) AS shapeId,
        TRIM(routeId) AS routeId,
        TRIM(currentDate) AS currentDate,
        TRIM(feedEndDate) AS feedEndDate,
        TRIM(routeColor) AS routeColor,
        TRIM(routeTextColor) AS routeTextColor,
        TRIM(tripId) AS tripId,
        TRIM(tripIdA) AS tripIdA,
        TRIM(tripIdB) AS tripIdB,
        TRIM(routeShortName) AS routeShortName,
        TRIM(routeLongName) AS routeLongName,
        TRIM(routeDesc) AS routeDesc,
        TRIM(stopId) AS stopId,
        TRIM(stopName) AS stopName,
        TRIM(serviceIdA) AS serviceIdA,
        TRIM(serviceIdB) AS serviceIdB,
        TRIM(departureTime) AS departureTime,
        TRIM(arrivalTime) AS arrivalTime,
        TRIM(parentStation) AS parentStation,
        TRIM(parentStopName) AS parentStopName
    FROM validation_notices
)

SELECT * FROM validation_notices_clean
