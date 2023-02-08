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
            WHEN 'Yes' THEN 'PASS'
            WHEN 'No' THEN 'FAIL'
            ELSE {{ manual_check_needed_status() }}
        END AS status,
    FROM idx
    LEFT JOIN gtfs_service_data
        ON idx.gtfs_service_data_key = gtfs_service_data.key
)

SELECT * FROM int_gtfs_quality__fixed_routes_match
