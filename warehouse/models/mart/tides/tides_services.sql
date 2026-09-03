{{
    config(
        materialized='table',
        tags=['tides_reference'],
    )
}}

-- Service reference for the published TIDES dataset: every service referenced
-- by a member organization's provider records. Gives the
-- `service_source_record_id` on tides_provider_gtfs_data a human-readable
-- service, valid for a given service date:
--     _valid_from <= service_date < _valid_to


WITH member_service_ids AS (
    SELECT DISTINCT service_source_record_id
    FROM {{ ref('tides_provider_gtfs_data') }}
    WHERE service_source_record_id IS NOT NULL
),

tides_services AS (
    SELECT
        key,
        source_record_id,
        name,
        ARRAY_TO_STRING(service_type, ", ") AS service_type,
        ARRAY_TO_STRING(mode, ", ") AS mode,
        ARRAY_TO_STRING(operating_counties, ", ") AS operating_counties,
        fixed_route,
        is_public,
        public_currently_operating,
        public_currently_operating_fixed_route,
        operational_status,
        _valid_from,
        _valid_to,
        _is_current
    FROM {{ ref('dim_services') }}
    WHERE source_record_id IN (
        SELECT service_source_record_id FROM member_service_ids
    )
)

SELECT * FROM tides_services
