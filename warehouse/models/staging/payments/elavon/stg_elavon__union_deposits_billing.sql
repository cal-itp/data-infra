{{ config(materialized='table') }}

WITH deposits AS (
    SELECT * FROM  {{ ref('fct_elavon__deposits') }}
),

billing AS (
    SELECT * FROM  {{ ref('stg_elavon__billing') }}
        -- this is a quick and dirty dedupe and needs to be replaced
    WHERE dt = '2023-04-10'
),

stg_elavon__union_deposits_billing AS (
    SELECT * FROM deposits

    UNION ALL

    SELECT * FROM billing
)

SELECT * FROM stg_elavon__union_deposits_billing
