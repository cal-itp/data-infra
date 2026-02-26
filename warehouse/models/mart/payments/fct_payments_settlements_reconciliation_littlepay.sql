WITH settlements AS (
    SELECT
        *,
        CASE settlement_type
            WHEN 'DEBIT' THEN 'sale'
            WHEN 'CREDIT' THEN 'refund'
        END AS transaction_type,
    FROM {{ ref('fct_payments_settlements') }}
),

deposit_transactions AS (
    SELECT
        *,
        CASE
            WHEN amount > 0 THEN 'sale'
            WHEN amount < 0 THEN 'refund'
        END AS transaction_type
    FROM {{ ref('fct_payments_deposit_transactions') }}
),

settlements_grouped AS (
  SELECT
    participant_id,
    customer_id,
    aggregation_id,
    retrieval_reference_number,
    settlement_type,
    transaction_type,
    TIMESTAMP_TRUNC(record_updated_timestamp_utc, DAY, 'America/Los_Angeles') AS record_updated_timestamp_pacific,
    settlement_status,
    SUM(transaction_amount) AS transaction_total
  FROM
    settlements
  WHERE
    COALESCE(aggregation_id, '') <> ''
    AND COALESCE(retrieval_reference_number, '') <> ''
    AND record_updated_timestamp_utc >= TIMESTAMP('2024-01-01 00:00:00-08:00')
  GROUP BY
    participant_id,
    customer_id,
    aggregation_id,
    retrieval_reference_number,
    settlement_type,
    record_updated_timestamp_pacific,
    settlement_status,
    transaction_type
),

deposits_grouped AS (
  SELECT
    purch_id,
    settlement_date,
    payment_date,
    transaction_type,
    SUM(amount) AS total_amount
  FROM deposit_transactions
  WHERE COALESCE(purch_id, '') <> ''
  GROUP BY
    purch_id,
    settlement_date,
    payment_date,
    transaction_type
),

fct_payments_settlements_reconciliation_littlepay AS (
    SELECT
        settlements_grouped.participant_id,
        settlements_grouped.retrieval_reference_number AS rrn,
        DATE(settlements_grouped.record_updated_timestamp_pacific) AS requested_for_settlement_date,
        settlements_grouped.settlement_type,
        settlements_grouped.settlement_status,
        settlements_grouped.transaction_total AS requested_for_settlement_amount,

        deposits_grouped.purch_id AS elavon_purch_id,
        deposits_grouped.total_amount AS elavon_amount,
        deposits_grouped.settlement_date AS elavon_settlement_date,
        deposits_grouped.payment_date AS elavon_payment_date

        FROM
        settlements_grouped
        LEFT JOIN deposits_grouped
        ON settlements_grouped.retrieval_reference_number = deposits_grouped.purch_id
        AND settlements_grouped.transaction_type = deposits_grouped.transaction_type
)

SELECT * FROM fct_payments_settlements_reconciliation_littlepay
