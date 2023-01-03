{{ config(materialized='table') }}

WITH latest_data_schemas AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__data_schemas'),
        order_by = 'dt DESC'
        ) }}
),

-- TODO: make this table actually historical
historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST((MIN(dt) OVER (ORDER BY dt)) AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_data_schemas
),

dim_data_schemas AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        name,
        status,
        _is_current,
        _valid_from,
        _valid_to
    FROM historical
)

SELECT * FROM dim_data_schemas
