WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_dataset_guideline_index') }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

int_gtfs_quality__link_to_dataset_on_website AS (
    SELECT
        idx.date,
        idx.gtfs_dataset_key,
        CASE
            WHEN gtfs_datasets.type = "schedule" THEN {{ link_to_dataset_on_website_schedule() }}
            WHEN gtfs_datasets.type = "vehicle_positions" THEN {{ link_to_dataset_on_website_vp() }}
            WHEN gtfs_datasets.type = "trip_updates" THEN {{ link_to_dataset_on_website_tu() }}
            WHEN gtfs_datasets.type = "service_alerts" THEN {{ link_to_dataset_on_website_sa() }}
        END AS check,
        {{ availability_on_website() }} AS feature,
        CASE manual_check__link_to_dataset_on_website
            WHEN 'Yes' THEN {{ guidelines_pass_status() }}
            WHEN 'No' THEN {{ guidelines_fail_status() }}
            ELSE {{ guidelines_manual_check_needed_status() }}
        END AS status
    FROM idx
    LEFT JOIN gtfs_datasets
         ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__link_to_dataset_on_website
