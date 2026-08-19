{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__rider_requirements',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['services',
                      'programs']
        ) }}
),
int_transit_database__rider_requirements_dim AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['id', '_valid_from']) }} AS key,
        id AS source_record_id,
        requirement,
        category,
        description,
        services,
        programs,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT *
FROM int_transit_database__rider_requirements_dim
