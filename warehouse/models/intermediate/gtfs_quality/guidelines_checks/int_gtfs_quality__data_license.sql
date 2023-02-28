WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__gtfs_dataset_guideline_index') }}
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

int_gtfs_quality__data_license AS (
    SELECT
        idx.date,
        idx.gtfs_dataset_key,
        CASE
            WHEN gtfs_datasets.type = "schedule" THEN {{ data_license_schedule() }}
            WHEN gtfs_datasets.type = "vehicle_positions" THEN {{ data_license_vp() }}
            WHEN gtfs_datasets.type = "trip_updates" THEN {{ data_license_tu() }}
            WHEN gtfs_datasets.type = "service_alerts" THEN {{ data_license_sa() }}
        END AS check,
        CASE
            WHEN gtfs_datasets.type = "schedule" THEN {{ compliance_schedule() }}
            WHEN gtfs_datasets.type IN ("vehicle_positions", "trip_updates", "service_alerts") THEN {{ compliance_rt() }}
        END AS feature,
        CASE
            WHEN manual_check__data_license LIKE ('%Permissive%')
                 OR manual_check__data_license LIKE ('%CC-BY%')
                 OR manual_check__data_license LIKE ('%ODL-BY%')
                THEN {{ guidelines_pass_status() }}
            WHEN manual_check__data_license LIKE ('%Restrictive%')
                 OR manual_check__data_license = 'Missing'
                THEN {{ guidelines_fail_status() }}
            WHEN manual_check__data_license = 'N/A - dataset is not public-facing' THEN {{ guidelines_na_check_status() }}
            ELSE {{ guidelines_manual_check_needed_status() }}
        END AS status
    FROM idx
    LEFT JOIN gtfs_datasets
        ON idx.gtfs_dataset_key = gtfs_datasets.key
)

SELECT * FROM int_gtfs_quality__data_license
