WITH
unfiltered_entries_latest AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
    WHERE _is_current
        AND private_dataset IS NOT TRUE
),

bridge_schedule_dataset_for_validation AS (
    SELECT * FROM {{ ref('bridge_schedule_dataset_for_validation') }}
    WHERE _is_current
),

service_source_record_ids AS (
    SELECT
        gtfs_service_data.gtfs_dataset_key,
        ARRAY_AGG(services.source_record_id IGNORE NULLS) AS service_source_record_ids
    FROM {{ ref('dim_gtfs_service_data') }} AS gtfs_service_data
    LEFT JOIN {{ ref('dim_services') }} AS services
        ON gtfs_service_data.service_key = services.key
    WHERE gtfs_service_data._is_current
        AND services._is_current
    GROUP BY 1
),

organization_source_record_ids AS (
    SELECT
        bridge.gtfs_dataset_key,
        ARRAY_AGG(organizations.source_record_id IGNORE NULLS) AS organization_source_record_ids
    FROM {{ ref('bridge_organizations_x_gtfs_datasets_produced') }} AS bridge
    LEFT JOIN {{ ref('dim_organizations') }} AS organizations
        ON bridge.organization_key = organizations.key
    WHERE bridge._is_current
        AND organizations._is_current
    GROUP BY 1
),

dim_gtfs_datasets_latest AS (
    SELECT
        unfiltered_entries_latest.source_record_id,
        unfiltered_entries_latest.name,
        unfiltered_entries_latest.type,
        unfiltered_entries_latest.regional_feed_type,
        unfiltered_entries_latest.base64_url as base64_url,
        CAST(FROM_BASE64(REPLACE(REPLACE(unfiltered_entries_latest.base64_url, '-', '+'), '_', '/')) as STRING) AS url,
        validation_schedule.base64_url AS schedule_to_use_for_rt_validation_base64_url,
        CAST(FROM_BASE64(REPLACE(REPLACE(validation_schedule.base64_url, '-', '+'), '_', '/')) as STRING) AS schedule_to_use_for_rt_validation_url,
        service_source_record_ids.service_source_record_ids,
        organization_source_record_ids.organization_source_record_ids
    FROM unfiltered_entries_latest
    LEFT JOIN bridge_schedule_dataset_for_validation
        ON unfiltered_entries_latest.key = bridge_schedule_dataset_for_validation.gtfs_dataset_key
    LEFT JOIN unfiltered_entries_latest AS validation_schedule
        ON bridge_schedule_dataset_for_validation.schedule_to_use_for_rt_validation_gtfs_dataset_key = validation_schedule.key
    LEFT JOIN service_source_record_ids
        ON unfiltered_entries_latest.key = service_source_record_ids.gtfs_dataset_key
    LEFT JOIN organization_source_record_ids
        ON unfiltered_entries_latest.key = organization_source_record_ids.gtfs_dataset_key
    WHERE unfiltered_entries_latest.deprecated_date IS NULL
)

SELECT * FROM dim_gtfs_datasets_latest
