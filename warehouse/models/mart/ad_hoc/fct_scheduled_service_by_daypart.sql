{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
),

extract_trip_date_types AS (

    SELECT

        CASE
            WHEN EXTRACT(hour FROM trip_first_departure_datetime_pacific) < 4 THEN "OWL"
            WHEN EXTRACT(hour FROM trip_first_departure_datetime_pacific) < 7 THEN "Early AM"
            WHEN EXTRACT(hour FROM trip_first_departure_datetime_pacific) < 10 THEN "AM Peak"
            WHEN EXTRACT(hour FROM trip_first_departure_datetime_pacific) < 15 THEN "Midday"
            WHEN EXTRACT(hour FROM trip_first_departure_datetime_pacific) < 20 THEN "PM Peak"
            ELSE "Evening"
        END
        AS time_of_day,

        gtfs_dataset_key,
        route_id,
        route_short_name,
        route_long_name,
        EXTRACT(hour FROM trip_first_departure_datetime_pacific) AS hour,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        EXTRACT(DAYOFWEEK from service_date) AS day_type,
        service_hours

    FROM fct_scheduled_trips

),

service_with_daypart AS (
    SELECT

        dim_gtfs_datasets.name,
        dim_gtfs_datasets.source_record_id,

        trips.time_of_day,
        trips.hour,
        trips.month,
        trips.year,
        trips.day_type,
        trips.route_id,
        trips.route_short_name,
        trips.route_long_name,
        trips.service_hours,

    FROM extract_trip_date_types AS trips
    LEFT JOIN dim_gtfs_datasets
        ON (trips.gtfs_dataset_key = dim_gtfs_datasets.key)

),

daypart_aggregations AS (
    SELECT

        name,
        source_record_id,
        route_id,
        route_short_name,
        route_long_name,
        time_of_day,
        hour,
        month,
        year,
        day_type,

        COUNT(*) AS n_trips,
        SUM(service_hours) AS ttl_service_hours

    FROM service_with_daypart
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),

fct_scheduled_service_by_daypart AS (
    SELECT

        name,
        source_record_id,
        route_id,
        route_short_name,
        route_long_name,
        time_of_day,
        hour,
        month,
        year,
        day_type,
        n_trips,
        ttl_service_hours

    FROM daypart_aggregations
)

SELECT * FROM fct_scheduled_service_by_daypart
