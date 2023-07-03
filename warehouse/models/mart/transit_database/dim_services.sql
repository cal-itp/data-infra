{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

dim_services AS (
    SELECT
        key,
        source_record_id,
        name,
        service_type,
        mode,
        operating_counties,
        gtfs_schedule_status, -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_quality, -- TODO: remove this field when v2, automatic determinations are available
        manual_check__gtfs_realtime_data_ingested_in_trip_planner,
        manual_check__gtfs_schedule_data_ingested_in_trip_planner,
        deprecated_date,
        fixed_route,
        is_public,
        public_currently_operating,
        public_currently_operating_fixed_route,
        start_date,
        operational_status,
        currently_operating AS _deprecated__currently_operating,
        assessment_status AS _deprecated__assessment_status,
        _valid_from,
        _valid_to,
        _is_current

    FROM dim
)

SELECT * FROM dim_services
