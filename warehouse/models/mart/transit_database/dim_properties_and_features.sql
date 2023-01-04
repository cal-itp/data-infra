{{ config(materialized='table') }}

WITH int_transit_database__properties_and_features_dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__properties_and_features_dim') }}
),

dim_properties_and_features AS (
    SELECT
        key,
        name,
        recommended_value,
        considerations,
        details,
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__properties_and_features_dim
)

SELECT * FROM dim_properties_and_features
