{{ config(materialized='table') }}

WITH latest_properties_and_features AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__properties_and_features'),
        order_by = 'dt DESC'
        ) }}
),

dim_properties_and_features AS (
    SELECT
        key,
        name,
        recommended_value,
        considerations,
        details,
        dt
    FROM latest_properties_and_features
)

SELECT * FROM dim_properties_and_features
