{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__components'),
        order_by = 'dt DESC'
        ) }}
),

dim_components AS (
    SELECT
        key,
        name,
        aliases,
        description,
        function_group,
        system,
        location,
        dt
    FROM latest
)

SELECT * FROM dim_components
