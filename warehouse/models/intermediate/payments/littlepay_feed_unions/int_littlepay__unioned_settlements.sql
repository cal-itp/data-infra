{{ config(materialized = "table") }}

WITH settlements_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__settlements') }}
),

settlements_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__settlements_v3') }}
),

int_littlepay__unioned_settlements AS (
    SELECT *
    FROM settlements_v1
    UNION ALL
    SELECT * FROM settlements_v3
)

SELECT * FROM int_littlepay__unioned_settlements
