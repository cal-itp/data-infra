{{ config(materialized = "table") }}

WITH micropayment_adjustments_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayment_adjustments') }}
),

micropayment_adjustments_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayment_adjustments_v3') }}
),

int_littlepay__unioned_micropayment_adjustments AS (
    SELECT *
    FROM micropayment_adjustments_v1
    UNION ALL
    SELECT * FROM micropayment_adjustments_v3
)

SELECT * FROM int_littlepay__unioned_micropayment_adjustments
