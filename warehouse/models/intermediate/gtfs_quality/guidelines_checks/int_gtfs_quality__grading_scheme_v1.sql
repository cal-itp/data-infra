WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ grading_scheme_v1() }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

check_start AS (
    SELECT MIN(_valid_from) AS first_check_date
    FROM gtfs_datasets
    WHERE manual_check__grading_scheme_v1 IS NOT NULL AND manual_check__grading_scheme_v1 != "Unknown"
),

int_gtfs_quality__grading_scheme_v1 AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        manual_check__grading_scheme_v1,
        CASE
            WHEN idx.has_gtfs_dataset_schedule
                   THEN
                    CASE
                        WHEN manual_check__grading_scheme_v1 = 'Yes' THEN {{ guidelines_pass_status() }}
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN manual_check__grading_scheme_v1 = 'Unknown' OR manual_check__grading_scheme_v1 IS NULL THEN {{ guidelines_manual_check_needed_status() }}
                        WHEN manual_check__grading_scheme_v1 = 'No' THEN {{ guidelines_fail_status() }}
                        WHEN manual_check__grading_scheme_v1 = 'N/A - dataset is not public-facing' THEN {{ guidelines_na_check_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__grading_scheme_v1
