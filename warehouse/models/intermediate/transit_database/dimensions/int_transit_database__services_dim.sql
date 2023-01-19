{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__services',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['service_type', 'fare_systems', 'mode', 'paratransit_for',
            'provider', 'operator', 'funding_sources', 'operating_counties']
        ) }}
),

int_transit_database__services_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS original_record_id,
        name,
        service_type,
        fare_systems,
        mode,
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
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM int_transit_database__services_dim
