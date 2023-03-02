WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_service_data_guideline_index') }}
),

gtfs_service_data AS (
    SELECT * FROM {{ ref('dim_gtfs_service_data') }}
),

int_gtfs_quality__fixed_routes_match AS (
    SELECT
        idx.date,
        idx.gtfs_service_data_key,
        {{ fixed_routes_match() }} AS check,
        {{ fixed_route_completeness() }} AS feature,
        CASE manual_check__fixed_route_completeness
            WHEN 'Complete' THEN {{ guidelines_pass_status() }}
            WHEN 'Incomplete' THEN {{ guidelines_fail_status() }}
            WHEN 'N/A' THEN {{ guidelines_na_check_status() }}
            ELSE {{ guidelines_manual_check_needed_status() }}
        END AS status,
    FROM idx
    LEFT JOIN gtfs_service_data
        ON idx.gtfs_service_data_key = gtfs_service_data.key
)

SELECT * FROM int_gtfs_quality__fixed_routes_match
