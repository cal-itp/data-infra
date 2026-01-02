{{ config(materialized='table') }}

-- scheduled trips: n_trips that started that hour for GTFS digest
-- scheduled stop times: aggregate stop arrivals by hour...but more interested in stop arrivals at stop by time-of-day for HQTA
WITH trips AS (
    SELECT *
    FROM {{ ref('fct_monthly_scheduled_trips') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

deduped_analysis_name AS (
    SELECT
        name,
        analysis_name,
        source_record_id,

    FROM dim_gtfs_datasets
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY source_record_id
        ORDER BY _valid_from DESC
    ) = 1
),

hourly_aggregation AS (
    SELECT
        trips.month_first_day,
        trips.name,
        deduped_analysis_name.analysis_name,
        trips.day_type,
        CAST(TRUNC(trips.trip_first_departure_sec / 3600) AS INT) AS departure_hour,

        COUNT(*) AS n_trips

    FROM trips
    INNER JOIN deduped_analysis_name
        ON trips.name = deduped_analysis_name.name
    GROUP BY 1, 2, 3, 4, 5
)

SELECT * FROM hourly_aggregation
