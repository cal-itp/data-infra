WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ stable_url_schedule() }},
        {{ stable_url_vp() }},
        {{ stable_url_tu() }},
        {{ stable_url_sa() }}
        )
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

check_start AS (
    SELECT MIN(_valid_from) AS first_check_date
    FROM gtfs_datasets
    WHERE manual_check__stable_url IS NOT NULL AND manual_check__stable_url != "Unknown"
),

int_gtfs_quality__stable_url AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        manual_check__stable_url,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN (idx.has_gtfs_dataset_schedule AND check = {{ stable_url_schedule() }})
                OR (idx.has_gtfs_dataset_vp AND check = {{ stable_url_vp() }})
                OR (idx.has_gtfs_dataset_tu AND check = {{ stable_url_tu() }})
                OR (idx.has_gtfs_dataset_sa AND check = {{ stable_url_sa() }})
                   THEN
                    CASE
                        WHEN manual_check__stable_url LIKE 'Yes%' THEN {{ guidelines_pass_status() }}
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN manual_check__stable_url = 'Unknown' OR manual_check__stable_url IS NULL THEN {{ guidelines_manual_check_needed_status() }}
                        WHEN manual_check__stable_url = 'No' THEN {{ guidelines_fail_status() }}
                        WHEN manual_check__stable_url = 'N/A - dataset is not public-facing' THEN {{ guidelines_na_check_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__stable_url
