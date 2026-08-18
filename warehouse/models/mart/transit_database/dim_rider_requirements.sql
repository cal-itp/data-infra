{{ config(materialized='table') }}

WITH dim AS (
    SELECT * FROM {{ ref('int_transit_database__rider_requirements_dim') }}
),
dim_rider_requirements AS (
    SELECT
        key,
        source_record_id,
        requirement,
        category,
        description,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT *
FROM dim_rider_requirements
