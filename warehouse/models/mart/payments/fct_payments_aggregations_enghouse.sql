{{ config(materialized = 'table',
    post_hook="{{ payments_enghouse_row_access_policy() }}") }}

WITH pay_windows AS (
    SELECT * FROM {{ ref('stg_enghouse__pay_windows') }}
),

taps_to_aggregations AS (
    SELECT * FROM {{ ref('int_payments__taps_to_aggregations_enghouse') }}
),

settlements_to_aggregations AS (
    SELECT * FROM {{ ref('int_payments__settlements_to_aggregations_enghouse') }}
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

elavon_info AS (
    SELECT
        enghouse_operator_id,
        purch_id AS elavon_purch_id,
        MAX(settlement_date) AS elavon_settlement_date,
        MAX(payment_date) AS elavon_payment_date,
        SUM(amount) AS elavon_net_amount,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS elavon_sales,
        SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) AS elavon_refunds
    FROM {{ ref('fct_payments_deposit_transactions') }}
    WHERE COALESCE(purch_id, '') != ''
    GROUP BY purch_id, enghouse_operator_id
),

join_all AS (
    SELECT
        pay_windows.operator_id,
        pay_windows.id AS pay_window_id,
        pay_windows.payment_reference,
        pay_windows.stage,
        pay_windows.terminal_id,
        pay_windows.open_timestamp,
        pay_windows.close_timestamp,
        -- the pay_windows table provides amount_to_settle and amount_settled in cents, rather than dollars
        pay_windows.amount_to_settle / 100 AS amount_to_settle_dollars,
        pay_windows.amount_settled / 100 AS amount_settled_dollars,
        pay_windows.debt_settled,
        pay_windows.agency,

        taps_to_aggregations.num_taps,
        taps_to_aggregations.latest_tap_terminal_date,
        taps_to_aggregations.masked_pan,
        taps_to_aggregations.num_ticket_results,
        taps_to_aggregations.total_fare_amount,
        taps_to_aggregations.latest_ticket_result_update_timestamp,

        settlements_to_aggregations.payment_reference IS NOT NULL AS has_settlement,
        settlements_to_aggregations.latest_settlement_update_timestamp,
        settlements_to_aggregations.latest_debit_operation,
        settlements_to_aggregations.latest_credit_operation,
        settlements_to_aggregations.num_settlements,
        settlements_to_aggregations.net_settlement_amount_dollars AS net_settled_amount_dollars,
        settlements_to_aggregations.contains_refund AS settlement_contains_refund,
        settlements_to_aggregations.par,
        settlements_to_aggregations.token,
        settlements_to_aggregations.brand,
        settlements_to_aggregations.aggregation_is_settled,
        settlements_to_aggregations.num_debit_settlements,
        settlements_to_aggregations.num_credit_settlements,
        settlements_to_aggregations.debit_amount AS settlement_debit_amount,
        settlements_to_aggregations.debit_is_settled,
        settlements_to_aggregations.credit_amount AS settlement_credit_amount,
        settlements_to_aggregations.credit_is_settled,
        settlements_to_aggregations.settled_credit_amount,
        settlements_to_aggregations.unsettled_credit_amount,

        COALESCE(
            pay_windows.close_timestamp,
            settlements_to_aggregations.latest_settlement_update_timestamp,
            pay_windows.open_timestamp,
            taps_to_aggregations.latest_tap_terminal_date
        ) AS aggregation_datetime, -- Q: what is the type here?

        elavon_info.elavon_purch_id,
        elavon_info.elavon_settlement_date,
        elavon_info.elavon_payment_date,
        elavon_info.elavon_net_amount,
        elavon_info.elavon_sales,
        elavon_info.elavon_refunds,

        dim_orgs.name AS organization_name,
        entity_map.organization_source_record_id

    FROM pay_windows
    LEFT JOIN taps_to_aggregations
        ON pay_windows.payment_reference = taps_to_aggregations.payment_reference
            AND pay_windows.operator_id = taps_to_aggregations.operator_id
    LEFT JOIN settlements_to_aggregations
        ON pay_windows.payment_reference = settlements_to_aggregations.payment_reference
            AND pay_windows.operator_id = settlements_to_aggregations.operator_id
    LEFT JOIN elavon_info
        ON pay_windows.payment_reference = elavon_info.elavon_purch_id
        and pay_windows.operator_id = elavon_info.enghouse_operator_id
    LEFT JOIN payments_entity_mapping AS entity_map
        ON pay_windows.operator_id = entity_map.operator_id
            AND CAST(pay_windows.open_timestamp AS TIMESTAMP)
                BETWEEN CAST(entity_map._in_use_from AS TIMESTAMP)
                AND CAST(entity_map._in_use_until AS TIMESTAMP)
    LEFT JOIN dim_orgs
        ON entity_map.organization_source_record_id = dim_orgs.source_record_id
            AND CAST(pay_windows.open_timestamp AS TIMESTAMP)
                BETWEEN dim_orgs._valid_from AND dim_orgs._valid_to
),

fct_payments_aggregations_enghouse AS (
    SELECT
        operator_id,
        organization_name,
        organization_source_record_id,
        LAST_DAY(EXTRACT(DATE FROM aggregation_datetime AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date_pacific,
        LAST_DAY(EXTRACT(DATE FROM aggregation_datetime), MONTH) AS end_of_month_date_utc,
        pay_window_id,
        payment_reference,
        masked_pan,
        par,
        token,
        brand,
        stage,
        terminal_id,
        DATETIME(open_timestamp, "UTC") AS open_datetime,
        DATETIME(open_timestamp, "America/Los_Angeles") AS open_datetime_pacific,
        DATETIME(close_timestamp, "UTC") AS close_datetime,
        DATETIME(close_timestamp, "America/Los_Angeles") AS close_datetime_pacific,
        DATETIME(aggregation_datetime, "UTC") AS aggregation_datetime,
        DATETIME(aggregation_datetime, "America/Los_Angeles") AS aggregation_datetime_pacific,
        agency,
        amount_to_settle_dollars,
        amount_settled_dollars,
        debt_settled,
        num_taps,
        DATETIME(latest_tap_terminal_date, "UTC") AS latest_tap_terminal_datetime,
        DATETIME(latest_tap_terminal_date, "America/Los_Angeles") AS latest_tap_terminal_datetime_pacific,
        num_ticket_results,
        total_fare_amount,
        DATETIME(latest_ticket_result_update_timestamp, "UTC") AS latest_ticket_result_update_datetime,
        DATETIME(latest_ticket_result_update_timestamp, "America/Los_Angeles") AS latest_ticket_result_update_datetime_pacific,
        has_settlement,
        DATETIME(latest_settlement_update_timestamp, "UTC") AS latest_settlement_update_datetime,
        DATETIME(latest_settlement_update_timestamp, "America/Los_Angeles") AS latest_settlement_update_datetime_pacific,
        latest_debit_operation,
        latest_credit_operation,
        num_settlements,
        num_debit_settlements,
        num_credit_settlements,
        net_settled_amount_dollars,
        settlement_contains_refund,
        aggregation_is_settled,
        settlement_debit_amount,
        debit_is_settled,
        settlement_credit_amount,
        credit_is_settled,
        settled_credit_amount,
        unsettled_credit_amount,
        settlement_debit_amount > 0 AS contains_nonzero_sales,
        elavon_purch_id,
        elavon_settlement_date,
        elavon_payment_date,
        elavon_net_amount,
        elavon_sales,
        elavon_refunds,
        CASE
            WHEN total_fare_amount = 0 THEN 'Zero-dollar value sales'
            WHEN stage = 'Closed' AND elavon_purch_id IS NOT NULL THEN 'Settled non-zero sales (with Elavon match)'
            WHEN stage = 'Closed' AND elavon_purch_id IS NULL THEN 'Settled non-zero sales (no Elavon match)'
            WHEN stage in ('Debt', 'Open', 'NoAuthDone') THEN 'Unsettled non-zero sales'
            WHEN stage in ('AuthDeclined', 'DebtFinal') THEN 'Declined sales'
            ELSE 'UNKNOWN'
        END AS reconciliation_category
    FROM join_all
)

SELECT * FROM fct_payments_aggregations_enghouse
