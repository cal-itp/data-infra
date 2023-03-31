WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ authentication_acceptable_schedule() }},
        {{ authentication_acceptable_vp() }},
        {{ authentication_acceptable_tu() }},
        {{ authentication_acceptable_sa() }}
        )
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

check_start AS (
    SELECT MIN(_valid_from) AS first_check_date
    FROM gtfs_datasets
    WHERE manual_check__authentication_acceptable IS NOT NULL AND manual_check__authentication_acceptable != "Unknown"
),

int_gtfs_quality__authentication_acceptable AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        manual_check__authentication_acceptable,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN (idx.has_gtfs_dataset_schedule AND check = {{ authentication_acceptable_schedule() }})
                OR (idx.has_gtfs_dataset_vp AND check = {{ authentication_acceptable_vp() }})
                OR (idx.has_gtfs_dataset_tu AND check = {{ authentication_acceptable_tu() }})
                OR (idx.has_gtfs_dataset_sa AND check = {{ authentication_acceptable_sa() }})
                   THEN
                    CASE
                        WHEN manual_check__authentication_acceptable = 'Yes' THEN {{ guidelines_pass_status() }}
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN manual_check__authentication_acceptable = 'Unknown' OR manual_check__authentication_acceptable IS NULL THEN {{ guidelines_manual_check_needed_status() }}
                        WHEN manual_check__authentication_acceptable = 'No' THEN {{ guidelines_fail_status() }}
                        WHEN manual_check__authentication_acceptable = 'N/A - dataset is not public-facing' THEN {{ guidelines_na_check_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__authentication_acceptable
