{{ config(materialized='table') }}

WITH int_transit_database__funding_programs_dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__funding_programs_dim') }}
),

dim_funding_programs AS (
    SELECT
        key,
        program,
        category,
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__funding_programs_dim
)

SELECT * FROM dim_funding_programs
