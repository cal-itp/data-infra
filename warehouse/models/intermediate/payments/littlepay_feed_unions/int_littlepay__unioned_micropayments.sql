{{ config(materialized = "table") }}

WITH micropayments_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayments') }}
),

micropayments_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayments_v3') }}
),

int_littlepay__unioned_micropayments AS (
    SELECT *
    FROM micropayments_v1
    UNION ALL
    SELECT * FROM micropayments_v3
)

SELECT * FROM int_littlepay__unioned_micropayments
