{{ config(materialized = 'table',
    post_hook="{{ payments_enghouse_row_access_policy() }}") }}

WITH pay_windows AS (
    SELECT * FROM {{ ref('stg_enghouse__pay_windows') }}
),

taps AS (
    SELECT * FROM {{ ref('stg_enghouse__taps') }}
),

ticket_results AS (
    SELECT * FROM {{ ref('stg_enghouse__ticket_results') }}
),

transactions AS (
    SELECT * FROM {{ ref('stg_enghouse__transactions') }}
),

payments_entity_mapping AS (
    SELECT
        * EXCEPT(enghouse_operator_id),
        enghouse_operator_id AS operator_id
    FROM {{ ref('payments_entity_mapping_enghouse') }}
),

dim_orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

ticket_results_by_payment_reference AS (
    SELECT
        taps.payment_reference,
        taps.operator_id,
        COUNT(DISTINCT taps.tap_id) AS num_taps,
        COUNT(ticket_results.id) AS num_ticket_results,
        SUM(ticket_results.amount) AS total_fare_amount
    FROM taps
    LEFT JOIN ticket_results
        ON taps.tap_id = ticket_results.tap_id
    WHERE taps.payment_reference IS NOT NULL
    GROUP BY taps.payment_reference, taps.operator_id
),

transactions_by_payment_reference AS (
    SELECT
        payment_reference,
        operator_id,
        COUNT(*) AS num_transactions,
        SUM(amount) AS net_transaction_amount,
        MAX(timestamp) AS latest_transaction_timestamp,
        COUNTIF(amount > 0) AS num_charges,
        COUNTIF(amount < 0) AS num_refunds,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS gross_charges,
        SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) AS gross_refunds
    FROM transactions
    WHERE payment_reference IS NOT NULL
    GROUP BY payment_reference, operator_id
),

elavon_info AS (
    SELECT
        purch_id AS elavon_purch_id,
        MAX(settlement_date) AS elavon_settlement_date,
        MAX(payment_date) AS elavon_payment_date,
        SUM(amount) AS elavon_net_amount,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS elavon_sales,
        SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) AS elavon_refunds
    FROM {{ ref('fct_payments_deposit_transactions') }}
    WHERE COALESCE(purch_id, '') != ''
    GROUP BY purch_id
),

join_all AS (
    SELECT
        pay_windows.operator_id,
        pay_windows.id AS pay_window_id,
        pay_windows.payment_reference,
        pay_windows.token,
        pay_windows.stage,
        pay_windows.terminal_id,
        pay_windows.open_date,
        pay_windows.close_date,
        pay_windows.amount_to_settle,
        pay_windows.amount_settled,
        pay_windows.debt_settled,
        pay_windows.agency,

        ticket_results_by_payment_reference.num_taps,
        ticket_results_by_payment_reference.num_ticket_results,
        ticket_results_by_payment_reference.total_fare_amount,

        transactions_by_payment_reference.num_transactions,
        transactions_by_payment_reference.net_transaction_amount,
        transactions_by_payment_reference.latest_transaction_timestamp,
        transactions_by_payment_reference.num_charges,
        transactions_by_payment_reference.num_refunds,
        transactions_by_payment_reference.gross_charges,
        transactions_by_payment_reference.gross_refunds,

        elavon_info.elavon_purch_id,
        elavon_info.elavon_settlement_date,
        elavon_info.elavon_payment_date,
        elavon_info.elavon_net_amount,
        elavon_info.elavon_sales,
        elavon_info.elavon_refunds,

        dim_orgs.name AS organization_name,
        entity_map.organization_source_record_id

    FROM pay_windows
    LEFT JOIN ticket_results_by_payment_reference
        ON pay_windows.payment_reference = ticket_results_by_payment_reference.payment_reference
            AND pay_windows.operator_id = ticket_results_by_payment_reference.operator_id
    LEFT JOIN transactions_by_payment_reference
        ON pay_windows.payment_reference = transactions_by_payment_reference.payment_reference
            AND pay_windows.operator_id = transactions_by_payment_reference.operator_id
    LEFT JOIN elavon_info
        ON pay_windows.payment_reference = elavon_info.elavon_purch_id
    LEFT JOIN payments_entity_mapping AS entity_map
        ON pay_windows.operator_id = entity_map.operator_id
            AND CAST(pay_windows.open_date AS TIMESTAMP)
                BETWEEN CAST(entity_map._in_use_from AS TIMESTAMP)
                AND CAST(entity_map._in_use_until AS TIMESTAMP)
    LEFT JOIN dim_orgs
        ON entity_map.organization_source_record_id = dim_orgs.source_record_id
            AND CAST(pay_windows.open_date AS TIMESTAMP)
                BETWEEN dim_orgs._valid_from AND dim_orgs._valid_to
),

fct_payments_aggregations_enghouse AS (
    SELECT
        operator_id,
        organization_name,
        organization_source_record_id,
        LAST_DAY(EXTRACT(DATE FROM open_date AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date_pacific,
        LAST_DAY(EXTRACT(DATE FROM open_date), MONTH) AS end_of_month_date_utc,
        pay_window_id,
        payment_reference,
        token,
        stage,
        terminal_id,
        open_date,
        close_date,
        agency,
        amount_to_settle,
        amount_settled,
        debt_settled,
        num_taps,
        num_ticket_results,
        total_fare_amount,
        num_transactions,
        net_transaction_amount,
        latest_transaction_timestamp,
        num_charges,
        num_refunds,
        gross_charges,
        gross_refunds,
        elavon_purch_id,
        elavon_settlement_date,
        elavon_payment_date,
        elavon_net_amount,
        elavon_sales,
        elavon_refunds,
        CASE
            WHEN stage = 'Closed' AND elavon_purch_id IS NOT NULL THEN 'Settled (with Elavon match)'
            WHEN stage = 'Closed' AND elavon_purch_id IS NULL THEN 'Settled (no Elavon match)'
            WHEN stage = 'Debt' THEN 'Debt (recovery ongoing)'
            WHEN stage = 'DebtFinal' THEN 'Debt (unrecovered)'
            WHEN stage IN ('Open', 'NoAuthDone') THEN 'Open'
            WHEN stage = 'AuthDeclined' THEN 'Authorization Declined'
            ELSE 'Unknown'
        END AS reconciliation_category
    FROM join_all
)

SELECT * FROM fct_payments_aggregations_enghouse
