{{ config(materialized='table') }}

WITH int_transit_database__components_dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__components_dim') }}
),

dim_components AS (
    SELECT
        key,
        original_record_id,
        name,
        aliases,
        description,
        function_group,
        system,
        location,
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__components_dim
)

SELECT * FROM dim_components
