WITH stg_littlepay__micropayments AS (
    SELECT * FROM {{ ref('stg_littlepay__micropayments') }}
),

stg_littlepay__micropayment_device_transactions AS (
    SELECT * FROM {{ ref('int_littlepay__cleaned_micropayment_device_transactions') }}
),

stg_littlepay__device_transactions AS (
    SELECT * FROM {{ ref('stg_littlepay__device_transactions') }}
),

single_device_transaction_ids AS (
    SELECT littlepay_transaction_id
    FROM stg_littlepay__micropayments AS m
    INNER JOIN stg_littlepay__micropayment_device_transactions USING (micropayment_id)
    INNER JOIN stg_littlepay__device_transactions USING (littlepay_transaction_id)
    WHERE m.charge_type = 'flat_fare'
),

pending_device_transaction_ids AS (
    SELECT littlepay_transaction_id
    FROM stg_littlepay__micropayments AS m
    INNER JOIN stg_littlepay__micropayment_device_transactions USING (micropayment_id)
    INNER JOIN stg_littlepay__device_transactions USING (littlepay_transaction_id)
    WHERE m.charge_type = 'pending_charge_fare'
),

potential_tap_on_or_off_micropayment_device_transaction_ids AS (
    SELECT
        micropayment_id,
        littlepay_transaction_id,
        transaction_date_time_utc
    FROM stg_littlepay__micropayments AS m
    INNER JOIN stg_littlepay__micropayment_device_transactions USING (micropayment_id)
    INNER JOIN stg_littlepay__device_transactions USING (littlepay_transaction_id)
    WHERE m.charge_type = 'complete_variable_fare'
),

paired_device_transaction_ids AS (
    SELECT
        t1.littlepay_transaction_id AS tap_on_littlepay_transaction_id,
        t2.littlepay_transaction_id AS tap_off_littlepay_transaction_id
    FROM potential_tap_on_or_off_micropayment_device_transaction_ids AS t1
    INNER JOIN potential_tap_on_or_off_micropayment_device_transaction_ids AS t2 USING (micropayment_id)
    WHERE t1.transaction_date_time_utc < t2.transaction_date_time_utc
),

int_littlepay__device_transaction_types AS (

    SELECT
        littlepay_transaction_id,
        'single' AS transaction_type,
        False AS pending
    FROM single_device_transaction_ids

    UNION ALL

    SELECT
        littlepay_transaction_id,
        'on' AS transaction_type,
        True AS pending
    FROM pending_device_transaction_ids

    UNION ALL

    SELECT
        tap_on_littlepay_transaction_id AS littlepay_transaction_id,
        'on' AS transaction_type,
        False AS pending
    FROM paired_device_transaction_ids

    UNION ALL

    SELECT
        tap_off_littlepay_transaction_id AS littlepay_transaction_id,
        'off' AS transaction_type,
        False AS pending
    FROM paired_device_transaction_ids
)

SELECT * FROM int_littlepay__device_transaction_types
