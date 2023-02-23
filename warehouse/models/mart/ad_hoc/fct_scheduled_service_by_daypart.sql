{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

fct_daily_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_daily_scheduled_trips') }}
    WHERE activity_date >= '2022-12-01' AND activity_date < '2023-01-01'
),

extract_trip_date_types AS (

    SELECT

        CASE
            WHEN EXTRACT(hour FROM activity_first_departure) < 4 THEN "OWL"
            WHEN EXTRACT(hour FROM activity_first_departure) < 7 THEN "Early AM"
            WHEN EXTRACT(hour FROM activity_first_departure) < 10 THEN "AM Peak"
            WHEN EXTRACT(hour FROM activity_first_departure) < 15 THEN "Midday"
            WHEN EXTRACT(hour FROM activity_first_departure) < 20 THEN "PM Peak"
            ELSE "Evening"
        END
        AS time_of_day,

        gtfs_dataset_key,
        shape_id,
        route_id,
        route_short_name,
        EXTRACT(hour FROM activity_first_departure) AS hour,
        EXTRACT(month FROM activity_date) AS month,
        EXTRACT(year FROM activity_date) AS year,
        EXTRACT(DAYOFWEEK from activity_date) AS day_type

    FROM fct_daily_scheduled_trips

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
        trips.shape_id,
        trips.route_id,
        trips.route_short_name

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
        shape_id,
        time_of_day,
        hour,
        month,
        year,
        day_type,

        COUNT(*) AS n_trips

    FROM service_with_daypart
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),

fct_scheduled_service_by_daypart AS (
    SELECT

        name,
        source_record_id,
        route_id,
        route_short_name,
        shape_id,
        time_of_day,
        hour,
        month,
        year,
        day_type,
        n_trips

    FROM daypart_aggregations
)

SELECT * FROM fct_scheduled_service_by_daypart
