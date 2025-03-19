{{ config(materialized = "table") }}

WITH authorisations_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__authorisations') }}
),

authorisations_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__authorisations_v3') }}
),

int_littlepay__unioned_authorisations AS (
    SELECT *
    FROM authorisations_v1
    UNION ALL
    SELECT * FROM authorisations_v3
)

SELECT * FROM int_littlepay__unioned_authorisations
