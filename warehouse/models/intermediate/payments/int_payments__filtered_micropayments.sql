{{ config(materialized = "table") }}

WITH micropayments AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_micropayments') }}
),

int_payments__filtered_micropayments AS (
    SELECT *
    FROM micropayments
    WHERE status != 'DELETED' OR status IS NULL
)

SELECT * FROM int_payments__filtered_micropayments
