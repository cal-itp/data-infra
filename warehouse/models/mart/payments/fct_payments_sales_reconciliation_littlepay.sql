WITH rides AS (
  SELECT * FROM {{ ref('fct_payments_rides_v2') }}
),

fct_settlements AS (
  SELECT * FROM {{ ref('fct_payments_settlements') }}
),

fct_deposits AS (
  SELECT
    *,
    CASE
      WHEN amount > 0 THEN 'DEBIT'
      WHEN amount < 0 THEN 'CREDIT'
    END AS elavon_settlement_type
   FROM {{ ref('fct_payments_deposit_transactions') }}
),

aggregations AS (
  SELECT * FROM {{ ref('fct_payments_aggregations') }}
),

base_sales AS (
  SELECT
    participant_id,
    card_scheme,
    bin,
    micropayment_id,
    aggregation_id,
    principal_customer_id,
    charge_amount,
    nominal_amount,
    transaction_date_pacific
  FROM rides
  WHERE transaction_date_pacific > DATE('2023-12-31')
),

aggregated_sales AS (
  SELECT
    aggregation_id,
    participant_id,
    card_scheme,
    bin,
    principal_customer_id,
    SUM(nominal_amount) AS total_nominal_charge,
    SUM(charge_amount) AS total_charge_amount,
    MAX(DATE_TRUNC(transaction_date_pacific, DAY)) AS max_date,
    COUNT(DISTINCT micropayment_id) AS count_micropayments
  FROM
    base_sales
  GROUP BY
    aggregation_id,
    participant_id,
    card_scheme,
    bin,
    principal_customer_id
),

settlements AS (
  SELECT
    participant_id,
    customer_id,
    aggregation_id,
    retrieval_reference_number,
    settlement_type,
    TIMESTAMP_TRUNC(record_updated_timestamp_utc, DAY, 'America/Los_Angeles') AS record_updated_timestamp_pacific,
    settlement_status,
    SUM(transaction_amount) AS total_transaction_amount
  FROM fct_settlements
    WHERE COALESCE(aggregation_id, '') != ''
    AND COALESCE(retrieval_reference_number, '') != ''
    AND record_updated_timestamp_utc >= TIMESTAMP('2024-01-01 00:00:00-08:00')
  GROUP BY
    participant_id,
    customer_id,
    aggregation_id,
    retrieval_reference_number,
    settlement_type,
    record_updated_timestamp_pacific,
    settlement_status
),

deposits AS (
  SELECT
    purch_id,
    settlement_date,
    payment_date,
    elavon_settlement_type,
    SUM(amount) AS total_amount,
  FROM fct_deposits
  WHERE COALESCE(purch_id, '') != ''
  GROUP BY
    purch_id,
    settlement_date,
    payment_date,
    elavon_settlement_type
),

authorisation AS (
  SELECT
    aggregation_id,
    latest_authorisation_status
  FROM aggregations
),

fct_payments_sales_reconciliation_littlepay AS (
  SELECT
    aggregated_sales.participant_id,
    aggregated_sales.card_scheme,
    aggregated_sales.bin,
    aggregated_sales.principal_customer_id,
    aggregated_sales.aggregation_id,
    settlements.retrieval_reference_number AS rrn,

    aggregated_sales.count_micropayments AS micropayments_in_aggregation,
    aggregated_sales.max_date AS transaction_date_pacific,
    aggregated_sales.total_nominal_charge AS nominal_amount,
    aggregated_sales.total_charge_amount AS charge_amount,

    DATE(settlements.record_updated_timestamp_pacific) AS requested_for_settlement_date,
    settlements.settlement_type,
    settlements.settlement_status,
    settlements.total_transaction_amount AS requested_for_settlement_amount,

    deposits.purch_id AS elavon_purch_id,
    deposits.total_amount AS elavon_amount,
    deposits.settlement_date AS elavon_settlement_date,
    deposits.payment_date AS elavon_payment_date,

    authorisation.latest_authorisation_status,

    CASE
      WHEN aggregated_sales.total_charge_amount = 0 THEN 'Zero-dollar value sales'
      WHEN aggregated_sales.total_charge_amount > 0
        AND settlements.settlement_status = 'SETTLED'
        AND deposits.purch_id IS NOT NULL
        AND deposits.purch_id != ''
        THEN 'Settled non-zero sales (with Elavon match)'
      WHEN aggregated_sales.total_charge_amount > 0
        AND settlements.settlement_status = 'SETTLED'
        AND (deposits.purch_id IS NULL OR deposits.purch_id = '')
        THEN 'Settled non-zero sales (no Elavon match)'
      WHEN aggregated_sales.total_charge_amount > 0
        AND (authorisation.latest_authorisation_status IS NULL
          OR authorisation.latest_authorisation_status NOT IN ('LOST','DECLINED','UNAVAILABLE','UNRECOVERABLE','INVALID'))
        AND (settlements.settlement_status IS NULL OR settlements.settlement_status != 'SETTLED')
        THEN 'Unsettled non-zero sales'
      WHEN authorisation.latest_authorisation_status IS NOT NULL
        AND authorisation.latest_authorisation_status != ''
        AND authorisation.latest_authorisation_status NOT IN ('AUTHORISED', 'VERIFIED')
        THEN 'Declined sales'
      ELSE 'Unknown'
    END AS reconciliation_category

  FROM aggregated_sales

  LEFT JOIN settlements
  ON aggregated_sales.aggregation_id = settlements.aggregation_id
  -- only want the sales to match
  AND settlements.settlement_type = 'DEBIT'

  LEFT JOIN deposits
  ON settlements.retrieval_reference_number = deposits.purch_id
  AND settlements.settlement_type = deposits.elavon_settlement_type

  LEFT JOIN authorisation
  ON aggregated_sales.aggregation_id = authorisation.aggregation_id
)

SELECT * FROM fct_payments_sales_reconciliation_littlepay
