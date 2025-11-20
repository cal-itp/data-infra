{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH daily_schedule_service AS (
    SELECT
        service_date,
        gtfs_dataset_key,
        ttl_service_hours,
        n_trips,
        n_routes,

    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.fct_daily_feed_scheduled_service_summary` --{{ ref('fct_daily_feed_scheduled_service_summary') }}
),

fct_observed_trips AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.test_fct_observed_trips`--{{ ref('fct_observed_trips') }}
),

observed_trips AS (
    SELECT
        *,
        -- num_distinct_message_keys = num_distinct_extract_ts and
        -- num_distinct_message_keys / extract_duration_minutes = messages per minute this entity was present for, how continuously this trip was updated.
        SAFE_DIVIDE(vp_num_distinct_extract_ts, vp_extract_duration_minutes) AS vp_messages_per_minute,
        SAFE_DIVIDE(tu_num_distinct_extract_ts, tu_extract_duration_minutes) AS tu_messages_per_minute,
    FROM fct_observed_trips
),

-- not sure if these deduped_analysis_name will capture all the rows,
-- seems to be missing a couple of them
dim_gtfs_datasets AS (
    SELECT *
    FROM `cal-itp-data-infra.mart_transit_database.dim_gtfs_datasets` --{{ ref('dim_gtfs_datasets') }}
    WHERE analysis_name IS NOT NULL
),

deduped_analysis_name AS (
    SELECT
        base64_url,
        name,
        analysis_name,

    FROM dim_gtfs_datasets
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY base64_url, analysis_name
        ORDER BY _valid_from DESC
    ) = 1
),

scheduled_trips AS (
    SELECT
        service_date,
        gtfs_dataset_key,
        base64_url,
        trip_instance_key,
        route_id
    FROM `cal-itp-data-infra.mart_gtfs.fct_scheduled_trips`--{{ ref('fct_scheduled_trips') }}
    WHERE service_date >= "2025-01-01"
),

trip_join AS (
    SELECT
        scheduled_trips.service_date,
        scheduled_trips.trip_instance_key,
        scheduled_trips.route_id,

        observed_trips.* EXCEPT(service_date, trip_instance_key),

        daily_schedule_service.* EXCEPT(service_date, gtfs_dataset_key),

    FROM scheduled_trips
    LEFT JOIN observed_trips
        ON observed_trips.service_date = scheduled_trips.service_date
        AND observed_trips.schedule_base64_url = scheduled_trips.base64_url
        AND observed_trips.trip_instance_key = scheduled_trips.trip_instance_key
    LEFT JOIN daily_schedule_service
      ON scheduled_trips.service_date = daily_schedule_service.service_date
      AND scheduled_trips.gtfs_dataset_key = daily_schedule_service.gtfs_dataset_key
),

summarize_service AS (
    SELECT
        service_date,
        schedule_base64_url,
        -- found North County Trip Updates which had only schedule_base64_url and nulls for key and name
        MAX(schedule_gtfs_dataset_key) AS schedule_gtfs_dataset_key,
        MAX(schedule_name) AS schedule_name,

        -- there can be trip_instance_keys where vp is present but not tu and vice versa
        -- if they share the same schedule_name, fill it in, since we're aggregating
        -- to operator.
        MAX(vp_gtfs_dataset_key) AS vp_gtfs_dataset_key,
        MAX(vp_name) AS vp_name,
        MAX(vp_base64_url) AS vp_base64_url,
        MAX(tu_gtfs_dataset_key) AS tu_gtfs_dataset_key,
        MAX(tu_name) AS tu_name,
        MAX(tu_base64_url) AS tu_base64_url,

        MAX(n_trips) AS n_trips,
        MAX(ttl_service_hours) AS ttl_service_hours,
        MAX(n_routes) AS n_routes,

        -- vehicle positions
        -- take average of vp per minute, every trip is equally weighted
        ROUND(AVG(vp_messages_per_minute), 2) AS vp_messages_per_minute,
        -- follow fct_daily_trip_updates_vehicle_positions_completeness
        COUNTIF(vp_num_distinct_message_ids > 0) AS n_vp_trips,
        ROUND(SAFE_DIVIDE(COUNTIF(vp_num_distinct_message_ids > 0), MAX(n_trips)), 2) AS pct_vp_trips,

        -- number of routes that had at least 1 trip with vp
        ROUND(SAFE_DIVIDE(COUNT(DISTINCT IF(vp_num_distinct_message_ids > 0, route_id, NULL)), MAX(n_routes)), 1) AS n_vp_routes,
        -- of total scheduled service minutes, how many was approx covered with vp
        ROUND(SAFE_DIVIDE(SUM(vp_extract_duration_minutes), MAX(ttl_service_hours * 60)), 2) AS pct_vp_service_hours,

        -- trip updates
        ROUND(AVG(tu_messages_per_minute), 2) AS tu_messages_per_minute,
        COUNTIF(tu_num_distinct_message_ids > 0) AS n_tu_trips,
        ROUND(SAFE_DIVIDE(COUNTIF(tu_num_distinct_message_ids > 0), MAX(n_trips)), 2) AS pct_tu_trips,
        ROUND(SAFE_DIVIDE(COUNT(DISTINCT IF(tu_num_distinct_message_ids > 0, route_id, NULL)), MAX(n_routes)), 1) AS n_tu_routes,
        ROUND(SAFE_DIVIDE(SUM(tu_extract_duration_minutes), MAX(ttl_service_hours * 60)), 2) AS pct_tu_service_hours,

    FROM trip_join
    GROUP BY service_date, schedule_base64_url
),

daily_summary AS (
    SELECT
        summarize_service.*,
        deduped_analysis_name.analysis_name,

        -- saw that some operators had only vp but not tu, so let's differentiate
        CASE
            WHEN n_tu_trips = 0 AND n_vp_trips = 0 THEN "schedule_only"
            WHEN n_tu_trips > 0 AND n_vp_trips > 0 THEN "schedule_and_rt"
            WHEN n_tu_trips > 0 AND n_vp_trips = 0 THEN "schedule_and_tu_only"
            WHEN n_tu_trips = 0 AND n_vp_trips > 0 THEN "schedule_and_vp_only"
            ELSE "unknown"
        END AS gtfs_availability,

    FROM summarize_service
    -- left join should tell us if we're missing analysis_name, need to fill these in
    LEFT JOIN deduped_analysis_name
        ON summarize_service.schedule_base64_url = deduped_analysis_name.base64_url
    WHERE schedule_name IS NOT NULL AND vp_name IS NOT NULL AND tu_name IS NOT NULL
)

SELECT * FROM daily_summary
