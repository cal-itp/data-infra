{{ config(materialized='table') }}

WITH fct_daily_feed_scheduled_service_summary AS (

    SELECT *
    FROM {{ ref('fct_daily_feed_scheduled_service_summary') }}

),

dim_provider_gtfs_data AS (

    SELECT *
    FROM {{ ref('dim_provider_gtfs_data') }}

),

daily_feed_organization_map AS (
    -- collapse the services level
    SELECT DISTINCT
        service_date,
        organization_name,
        organization_itp_id,
        organization_source_record_id,
        organization_key,
        feed_key,
    FROM fct_daily_feed_scheduled_service_summary AS service
    LEFT JOIN dim_provider_gtfs_data AS quartet
        ON CAST(service.service_date AS TIMESTAMP) BETWEEN quartet._valid_from AND quartet._valid_to
        AND service.gtfs_dataset_key = quartet.schedule_gtfs_dataset_key
),

fct_daily_organization_scheduled_service_summary AS (
    SELECT
        service_date,
        organization_name,
        organization_itp_id,
        organization_source_record_id,
        organization_key,
        SUM(ttl_service_hours) AS ttl_service_hours,
        SUM(n_trips) AS n_trips,
        MIN(first_departure_sec) AS first_departure_sec,
        MAX(last_arrival_sec) AS last_arrival_sec,
        SUM(n_stop_times) AS n_stop_times,
        SUM(n_routes) AS n_routes,
        COUNT(feed_key) AS feed_key_ct,
        COUNT(DISTINCT feed_key) AS distinct_feed_key_ct,
        LOGICAL_OR(
            contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id
    FROM daily_feed_organization_map
    LEFT JOIN fct_daily_feed_scheduled_service_summary
        USING (service_date, feed_key)
    GROUP BY service_date, organization_source_record_id, organization_name, organization_itp_id, organization_key
)

SELECT * FROM fct_daily_organization_scheduled_service_summary
