{{ config(materialized='table') }}

WITH stg_transit_database__properties_and_features AS (
    SELECT * FROM {{ ref('stg_transit_database__properties_and_features') }}
),

dim_properties_and_features AS (
    SELECT
        key,
        name,
        recommended_value,
        considerations,
        details,
        calitp_extracted_at
    FROM stg_transit_database__properties_and_features
)

SELECT * FROM dim_properties_and_features
