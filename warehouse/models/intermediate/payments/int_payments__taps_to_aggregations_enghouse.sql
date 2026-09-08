WITH taps AS (
    SELECT
        payment_reference,
        operator_id,
        terminal_date,
        masked_pan,
        par,
        token
     from {{ ref('stg_enghouse__taps') }} --todo: specify fields here
),

int_payments__taps_to_aggregations_enghouse AS (
    SELECT
        payment_reference,
        operator_id,
        COUNT(*) AS num_taps,
        MAX(terminal_date) AS latest_tap_terminal_date,
        ANY_VALUE(masked_pan) AS masked_pan,
        ANY_VALUE(par) AS par, -- TODO: set tests to ensure that taps PAR matches transactions PAR
        ANY_VALUE(token) AS token, -- TODO: set tests to ensure that taps token matches transactions token
    FROM taps
    WHERE payment_reference IS NOT NULL -- TODO: figure out why taps.payment_reference is sometimes null - this check should not be necessary
    GROUP BY payment_reference, operator_id
)

SELECT
    payment_reference,
    operator_id,
    num_taps,
    latest_tap_terminal_date,
    masked_pan,
    par,
    token
FROM int_payments__taps_to_aggregations_enghouse
