{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

bridge_services_x_county_geography AS (
    SELECT * FROM {{ ref('bridge_services_x_county_geography') }}
),

dim_services AS (
    SELECT

        dim.key,
        dim.source_record_id,
        dim.name,
        dim.service_type,
        dim.mode,
        dim.currently_operating,
        dim.operating_counties,
        dim.gtfs_schedule_status, -- TODO: remove this field when v2, automatic determinations are available
        dim.gtfs_schedule_quality, -- TODO: remove this field when v2, automatic determinations are available
        dim.assessment_status,
        dim.manual_check__gtfs_realtime_data_ingested_in_trip_planner,
        dim.manual_check__gtfs_schedule_data_ingested_in_trip_planner,
        dim.deprecated_date,

        geography_bridge.name AS operating_county_geographies,

        dim._valid_from,
        dim._valid_to,
        dim._is_current

    FROM dim
    LEFT JOIN bridge_services_x_county_geography AS geography_bridge
        ON dim.source_record_id = geography_bridge.source_record_id
)

SELECT * FROM dim_services
