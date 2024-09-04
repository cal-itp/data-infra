WITH
unfiltered_entries_latest AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
    WHERE _is_current
        AND !private_dataset
),

bridge_schedule_dataset_for_validation AS (
    SELECT * FROM {{ ref('bridge_schedule_dataset_for_validation') }}
    where _is_current
),

dim_gtfs_datasets_latest AS (
    SELECT
        unfiltered_entries_latest.name,
        unfiltered_entries_latest.type,
        unfiltered_entries_latest.regional_feed_type,
        unfiltered_entries_latest.base64_url as base64_url,
        CAST(FROM_BASE64(REPLACE(REPLACE(unfiltered_entries_latest.base64_url, '-', '+'), '_', '/')) as STRING) AS url,
        validation_schedule.base64_url AS schedule_to_use_for_rt_validation_base64_url,
        CAST(FROM_BASE64(REPLACE(REPLACE(validation_schedule.base64_url, '-', '+'), '_', '/')) as STRING) AS schedule_to_use_for_rt_validation_url
    FROM unfiltered_entries_latest
    LEFT JOIN bridge_schedule_dataset_for_validation
        ON unfiltered_entries_latest.key = bridge_schedule_dataset_for_validation.gtfs_dataset_key
    LEFT JOIN unfiltered_entries_latest AS validation_schedule
        ON bridge_schedule_dataset_for_validation.schedule_to_use_for_rt_validation_gtfs_dataset_key = validation_schedule.key
    WHERE unfiltered_entries_latest.deprecated_date IS NULL
)

SELECT * FROM dim_gtfs_datasets_latest
