WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_dataset_guideline_index') }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

int_gtfs_quality__authentication_acceptable AS (
    SELECT
        idx.date,
        idx.gtfs_dataset_key,
        CASE
            WHEN gtfs_datasets.type = "schedule" THEN {{ authentication_acceptable_schedule() }}
            WHEN gtfs_datasets.type = "vehicle_positions" THEN {{ authentication_acceptable_vp() }}
            WHEN gtfs_datasets.type = "trip_updates" THEN {{ authentication_acceptable_tu() }}
            WHEN gtfs_datasets.type = "service_alerts" THEN {{ authentication_acceptable_sa() }}
        END AS check,
        {{ availability_on_website() }} AS feature,
        CASE manual_check__authentication_acceptable
            WHEN 'Yes' THEN 'PASS'
            WHEN 'No' THEN 'FAIL'
            ELSE 'Needs manual check'
        END AS status
    FROM idx
    LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__authentication_acceptable
