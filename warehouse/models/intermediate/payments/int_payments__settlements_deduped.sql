WITH settlements_unioned AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_settlements') }}
),

int_payments__settlements_deduped AS (
    SELECT
        *
    FROM settlements_unioned
    -- see: https://github.com/cal-itp/data-infra/issues/4552
    -- we have cases where same settlement comes in with two statuses
    -- only want to keep one instance -- the more recent one
    QUALIFY ROW_NUMBER() OVER
        (PARTITION BY participant_id, _payments_key, transaction_amount
        ORDER BY record_updated_timestamp_utc DESC, _line_number ASC) = 1
)

SELECT * FROM int_payments__settlements_deduped
