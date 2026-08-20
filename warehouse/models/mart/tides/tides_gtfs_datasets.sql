{{
    config(
        materialized='table',
        tags=['tides_reference'],
    )
}}

-- GTFS dataset reference for the published TIDES dataset:
-- Resolves the `gtfs_dataset_key` / `base64_url` carried on
-- vehicle_locations / trips_performed to a named feed, valid for a given
-- service date:
--     _valid_from <= service_date < _valid_to


WITH provider_records AS (
    SELECT * FROM {{ ref('tides_provider_gtfs_data') }}
),

referenced_dataset_keys AS (
    SELECT DISTINCT gtfs_dataset_key
    FROM (
        SELECT schedule_gtfs_dataset_key AS gtfs_dataset_key FROM provider_records
        UNION ALL
        SELECT service_alerts_gtfs_dataset_key FROM provider_records
        UNION ALL
        SELECT vehicle_positions_gtfs_dataset_key FROM provider_records
        UNION ALL
        SELECT trip_updates_gtfs_dataset_key FROM provider_records
        UNION ALL
        -- belt and braces: dataset keys actually observed in the facts
        SELECT gtfs_dataset_key FROM {{ ref('tides_publication_feeds') }}
    )
    WHERE gtfs_dataset_key IS NOT NULL
),

member_dataset_ids AS (
    SELECT DISTINCT source_record_id
    FROM {{ ref('dim_gtfs_datasets') }}
    WHERE key IN (SELECT gtfs_dataset_key FROM referenced_dataset_keys)
),

tides_gtfs_datasets AS (
    SELECT
        key,
        source_record_id,
        name,
        type,
        regional_feed_type,
        base64_url,
        CAST(FROM_BASE64(REPLACE(REPLACE(base64_url, '-', '+'), '_', '/')) AS STRING) AS url,
        has_authentication,
        authentication_contact_details,
        deprecated_date,
        _valid_from,
        _valid_to,
        _is_current
    FROM {{ ref('dim_gtfs_datasets') }}
    WHERE source_record_id IN (SELECT source_record_id FROM member_dataset_ids)
        AND private_dataset IS NOT TRUE
)

SELECT * FROM tides_gtfs_datasets
