{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__properties_and_features'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_properties_and_features AS (
    SELECT
        key,
        name,
        recommended_value,
        considerations,
        details,
        calitp_extracted_at
    FROM latest
)

SELECT * FROM dim_properties_and_features
