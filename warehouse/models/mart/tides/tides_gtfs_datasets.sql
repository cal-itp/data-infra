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

-- Historical feed versions whose URL carried an inline auth credential (?key=),
-- excluded so no feed key reaches the open-data bucket. Only these versions are
-- dropped; current versions are clean.
credential_bearing_versions AS (
    SELECT deny_source_record_id, deny_valid_from
    FROM UNNEST([
        STRUCT('recYNhwWlgv0xEQvQ' AS deny_source_record_id, TIMESTAMP '2025-10-15 00:00:00+00' AS deny_valid_from),  -- Bear Alerts
        STRUCT('rec50UrBVphNmIiTz', TIMESTAMP '2025-10-15 00:00:00+00'),  -- Bear Schedule
        STRUCT('recVwM5CcUf67mOsz', TIMESTAMP '2025-10-15 00:00:00+00'),  -- Bear Trip Updates
        STRUCT('reclEUVQ0e7JlwdB8', TIMESTAMP '2025-10-15 00:00:00+00'),  -- Bear Vehicle Positions
        STRUCT('recYDXYPHTZXX17DI', TIMESTAMP '2022-06-29 00:00:00+00'),  -- San Diego Trip Updates (v1)
        STRUCT('recYDXYPHTZXX17DI', TIMESTAMP '2022-08-09 00:00:00+00')   -- San Diego Trip Updates (v2)
    ])
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
        AND NOT EXISTS (
            SELECT 1
            FROM credential_bearing_versions
            WHERE deny_source_record_id = source_record_id
                AND deny_valid_from = _valid_from
        )
)

SELECT * FROM tides_gtfs_datasets
