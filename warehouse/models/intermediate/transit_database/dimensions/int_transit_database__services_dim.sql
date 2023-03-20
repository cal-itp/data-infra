{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__services',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['service_type', 'fare_systems', 'mode', 'primary_mode', 'paratransit_for',
            'provider', 'operator', 'funding_sources', 'operating_counties', 'operating_county_geographies']
        ) }}
),

int_transit_database__services_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS source_record_id,
        name,
        service_type,
        fare_systems,
        mode,
        primary_mode,
        currently_operating,
        paratransit_for,
        provider,
        operator,
        funding_sources,
        -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_status,
        -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_quality,
        operating_counties,
        assessment_status,
        manual_check__gtfs_realtime_data_ingested_in_trip_planner,
        manual_check__gtfs_schedule_data_ingested_in_trip_planner,
        deprecated_date,
        operating_county_geographies,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM int_transit_database__services_dim
