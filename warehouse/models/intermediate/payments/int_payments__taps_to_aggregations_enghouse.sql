WITH taps AS (
    SELECT
        tap_id,
        payment_reference,
        operator_id,
        terminal_date,
        masked_pan,
        par,
        token
     from {{ ref('stg_enghouse__taps') }}
),

ticket_results AS (
    SELECT
        tap_id,
        id,
        amount,
        GREATEST(
            COALESCE(start_dttm, end_dttm),
            COALESCE(end_dttm, start_dttm)
        ) AS ticket_result_update_timestamp
    FROM {{ ref('stg_enghouse__ticket_results') }}
),

int_payments__taps_to_aggregations_enghouse AS (
    SELECT
        taps.payment_reference,
        taps.operator_id,
        -- the join fans out for taps with more than one ticket result, so count taps distinctly
        COUNT(DISTINCT taps.tap_id) AS num_taps,
        MAX(taps.terminal_date) AS latest_tap_terminal_date,
        ANY_VALUE(taps.masked_pan) AS masked_pan,
        ANY_VALUE(taps.par) AS par,
        ANY_VALUE(taps.token) AS token,
        COUNT(ticket_results.id) AS num_ticket_results,
        SUM(ticket_results.amount) AS total_fare_amount,
        MAX(ticket_results.ticket_result_update_timestamp) AS latest_ticket_result_update_timestamp
    FROM taps
    LEFT JOIN ticket_results
        ON taps.tap_id = ticket_results.tap_id
    WHERE taps.payment_reference IS NOT NULL -- workaround for #5697
    GROUP BY taps.payment_reference, taps.operator_id
)

SELECT
    payment_reference,
    operator_id,
    num_taps,
    latest_tap_terminal_date,
    masked_pan,
    par,
    token,
    num_ticket_results,
    total_fare_amount,
    latest_ticket_result_update_timestamp
FROM int_payments__taps_to_aggregations_enghouse
