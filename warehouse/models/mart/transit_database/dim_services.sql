{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

dim_services AS (
    SELECT
        key,
        original_record_id,
        name,
        service_type,
        mode,
        currently_operating,
        operating_counties,
        -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_status,
        -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_quality,
        assessment_status,
        _valid_from,
        _valid_to,
        _is_current
    FROM dim
)

SELECT * FROM dim_services
