WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_dataset_schedule_guideline_index') }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

int_gtfs_quality__shapes_accurate AS (
    SELECT
        idx.date,
        idx.gtfs_dataset_key,
        {{ shapes_accurate() }} AS check,
        {{ accurate_service_data() }} AS feature,
        CASE
            WHEN manual_check__accurate_shapes = 'Yes' THEN {{ guidelines_pass_status() }}
            WHEN manual_check__accurate_shapes = 'No' THEN {{ guidelines_fail_status() }}
            WHEN manual_check__accurate_shapes LIKE 'N/A%' THEN {{ guidelines_na_check_status() }}
            ELSE {{ guidelines_manual_check_needed_status() }}
        END AS status,
    FROM idx
    LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__shapes_accurate
