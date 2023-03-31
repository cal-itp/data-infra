WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ data_license_schedule() }},
        {{ data_license_vp() }},
        {{ data_license_tu() }},
        {{ data_license_sa() }}
        )
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

check_start AS (
    SELECT MIN(_valid_from) AS first_check_date
    FROM gtfs_datasets
    WHERE manual_check__data_license IS NOT NULL AND manual_check__data_license != "Unknown"
),

int_gtfs_quality__data_license AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        manual_check__data_license,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN (idx.has_gtfs_dataset_schedule AND check = {{ data_license_schedule() }})
                OR (idx.has_gtfs_dataset_vp AND check = {{ data_license_vp() }})
                OR (idx.has_gtfs_dataset_tu AND check = {{ data_license_tu() }})
                OR (idx.has_gtfs_dataset_sa AND check = {{ data_license_sa() }})
                   THEN
                    CASE
                        WHEN manual_check__data_license LIKE ('%Permissive%')
                            OR manual_check__data_license LIKE ('%CC-BY%')
                            OR manual_check__data_license LIKE ('%ODL-BY%')
                            THEN {{ guidelines_pass_status() }}
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN manual_check__data_license = 'Unknown' OR manual_check__data_license IS NULL THEN {{ guidelines_manual_check_needed_status() }}
                        WHEN manual_check__data_license LIKE ('%Restrictive%')
                            OR manual_check__data_license = 'Missing'
                            THEN {{ guidelines_fail_status() }}
                        WHEN manual_check__data_license = 'N/A - dataset is not public-facing' THEN {{ guidelines_na_check_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__data_license
