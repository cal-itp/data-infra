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
        CASE manual_check__accurate_shapes
            WHEN 'Yes' THEN 'PASS'
            WHEN 'No' THEN 'FAIL'
            ELSE 'Needs manual check'
        END AS status,
    FROM idx
    LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__shapes_accurate
