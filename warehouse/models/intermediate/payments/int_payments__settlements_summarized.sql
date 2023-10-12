{{ config(materialized = 'table',) }}

WITH settlements AS (
    SELECT *
    FROM {{ ref('stg_littlepay__settlements') }}
)

-- TODO:
-- pair up debit with credit settlements to get final settled amount per aggregation id
-- question is how / whether to actually join with refunds
-- looks like settlements.type (which determines debit vs. credit) is not always populated :/
-- so we may need to join with refunds to determine which are credits

SELECT * FROM settlements
