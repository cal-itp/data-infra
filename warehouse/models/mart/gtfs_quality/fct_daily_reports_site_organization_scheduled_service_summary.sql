{{ config(materialized='table') }}

WITH fct_daily_feed_scheduled_service_summary AS (

    SELECT *
    FROM {{ ref('fct_daily_feed_scheduled_service_summary') }}

),

int_gtfs__organization_dataset_map AS (

    SELECT *
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    WHERE public_customer_facing_or_regional_subfeed

),

fct_daily_reports_site_organization_scheduled_service_summary AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['service_date', 'organization_key']) }} AS key,
        service_date,
        CASE
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 1 THEN "Sunday"
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 7 THEN "Saturday"
            ELSE "Weekday"
        END AS service_day_type,
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
        LOGICAL_OR(
            contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id
    FROM int_gtfs__organization_dataset_map
    INNER JOIN fct_daily_feed_scheduled_service_summary
        ON int_gtfs__organization_dataset_map.date = fct_daily_feed_scheduled_service_summary.service_date
        AND int_gtfs__organization_dataset_map.schedule_feed_key = fct_daily_feed_scheduled_service_summary.feed_key
    GROUP BY service_date, organization_source_record_id, organization_name, organization_itp_id, organization_key
)

SELECT * FROM fct_daily_reports_site_organization_scheduled_service_summary
