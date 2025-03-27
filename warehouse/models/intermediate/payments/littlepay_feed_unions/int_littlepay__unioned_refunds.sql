{{ config(materialized = "table") }}

WITH refunds_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__refunds') }}
),

refunds_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__refunds_v3') }}
),

int_littlepay__unioned_refunds AS (
    SELECT *
    FROM refunds_v1
    UNION ALL
    SELECT * FROM refunds_v3
)

SELECT * FROM int_littlepay__unioned_refunds
