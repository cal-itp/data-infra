{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__components'),
        order_by = 'dt DESC'
        ) }}
),

-- TODO: make this table actually historical
historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST(universal_first_val AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest
),

int_transit_database__components_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS source_record_id,
        name,
        aliases,
        products,
        contracts,
        properties_and_features,
        description,
        function_group,
        system,
        location,
        _is_current,
        _valid_from,
        _valid_to
    FROM historical
)

SELECT * FROM int_transit_database__components_dim
