WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_dataset_schedule_guideline_index') }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

int_gtfs_quality__grading_scheme_v1 AS (
    SELECT
        idx.date,
        idx.gtfs_dataset_key,
        {{ grading_scheme_v1() }} AS check,
        {{ compliance_schedule() }} AS feature,
        CASE manual_check__grading_scheme_v1
            WHEN 'Yes' THEN 'PASS'
            WHEN 'No' THEN 'FAIL'
            ELSE {{ manual_check_needed_status() }}
        END AS status,
    FROM idx
    LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__grading_scheme_v1
