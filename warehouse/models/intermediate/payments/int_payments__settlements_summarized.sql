{{ config(materialized = 'table',) }}

WITH settlements AS (
    SELECT *
    FROM {{ ref('stg_littlepay__settlements') }}
),

impute_settlement_type AS (
    SELECT
        * EXCEPT(settlement_type),
        COALESCE(settlement_type,
            -- when a settlement (aggregation_id / RRN) appears multiple times, it is generally because the subsequent lines are refunds
            -- vast majority of refunds have exactly one debit line and one credit (refund) line, but there are a few oddities with multiple credit (refund) lines
            CASE
                WHEN ROW_NUMBER() OVER(PARTITION BY aggregation_id, retrieval_reference_number ORDER BY settlement_requested_date_time_utc) > 1 THEN "CREDIT"
                ELSE "DEBIT"
            END
        ) AS settlement_type,
        settlement_type IS NULL AS imputed_type,
    FROM settlements
),

summarize_by_type AS (
    SELECT
        aggregation_id,
        retrieval_reference_number,
        settlement_type,
        LOGICAL_OR(imputed_type) AS contains_imputed_type,
        MAX(settlement_requested_date_time_utc) AS latest_update_timestamp,
        CASE
            WHEN settlement_type = "CREDIT" THEN -SUM(transaction_amount)
            WHEN settlement_type = "DEBIT" THEN SUM(transaction_amount)
        END AS total_amount,
    FROM impute_settlement_type
    GROUP BY 1,2,3

)

-- TODO:
-- pair up debit with credit settlements (pivot) to get final settled amount per aggregation id

SELECT * FROM summarize_by_type
