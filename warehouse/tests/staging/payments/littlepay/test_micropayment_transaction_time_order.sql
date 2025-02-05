{{ config(store_failures = true) }}

-- The timestamp on micropayment records should be at least as late as its
-- associated transactions timestamps.

WITH stg_littlepay__micropayments AS (

    SELECT * FROM {{ ref('stg_littlepay__micropayments') }}

),

int_payments__cleaned_micropayment_device_transactions AS (

    SELECT * FROM {{ ref('int_payments__cleaned_micropayment_device_transactions') }}

),

stg_littlepay__device_transactions AS (

    SELECT * FROM {{ ref('stg_littlepay__device_transactions') }}

),

validate_cleaned_micropayment_transaction_time_order AS (

    SELECT
        stg_littlepay__micropayments.micropayment_id,
        cast(transaction_time AS TIMESTAMP) AS transaction_time,
        littlepay_transaction_id,
        cast(
            transaction_date_time_utc AS TIMESTAMP
        ) AS transaction_date_time_utc
    FROM stg_littlepay__micropayments
    INNER JOIN
        int_payments__cleaned_micropayment_device_transactions ON
            stg_littlepay__micropayments.micropayment_id = int_payments__cleaned_micropayment_device_transactions.micropayment_id
    INNER JOIN
        stg_littlepay__device_transactions USING (littlepay_transaction_id)
    WHERE
        cast(
            transaction_time AS TIMESTAMP
        ) < cast(transaction_date_time_utc AS TIMESTAMP)
)

SELECT * FROM validate_cleaned_micropayment_transaction_time_order
