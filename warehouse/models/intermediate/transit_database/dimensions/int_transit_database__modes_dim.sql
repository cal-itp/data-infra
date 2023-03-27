{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__modes',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['services']
        ) }}
),

int_transit_database__modes_dim AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['id', '_valid_from']) }} AS key,
        id AS source_record_id,
        mode,
        super_mode,
        description,
        link_to_formal_definition,
        services,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM int_transit_database__modes_dim
