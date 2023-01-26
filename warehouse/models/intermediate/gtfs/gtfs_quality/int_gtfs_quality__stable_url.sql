WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_dataset_guideline_index') }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

int_gtfs_quality__stable_url AS (
    SELECT
        idx.date,
        idx.gtfs_dataset_key,
        CASE
            WHEN gtfs_datasets.type = "schedule" THEN {{ stable_url_schedule() }}
            WHEN gtfs_datasets.type = "vehicle_positions" THEN {{ stable_url_vp() }}
            WHEN gtfs_datasets.type = "trip_updates" THEN {{ stable_url_tu() }}
            WHEN gtfs_datasets.type = "service_alerts" THEN {{ stable_url_sa() }}
        END AS check,
        CASE
            WHEN gtfs_datasets.type = "schedule" THEN {{ compliance_schedule() }}
            WHEN gtfs_datasets.type IN ("vehicle_positions","trip_updates","service_alerts") THEN {{ compliance_rt() }}
        CASE manual_check__stable_url
            WHEN 'Yes' THEN 'PASS'
            WHEN 'No' THEN 'FAIL'
            ELSE {{ manual_check_needed_status() }}
        END AS status
    FROM idx
    LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__stable_url
