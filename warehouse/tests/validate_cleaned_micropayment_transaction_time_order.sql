WITH stg_cleaned_micropayments AS (

    SELECT * FROM {{ ref('stg_cleaned_micropayments') }}

),

stg_cleaned_micropayment_device_transactions AS (

    SELECT * FROM {{ ref('stg_cleaned_micropayment_device_transactions') }}

),

stg_cleaned_device_transactions AS (

    SELECT * FROM {{ ref('stg_cleaned_device_transactions') }}

),

validate_cleaned_micropayment_transaction_time_order AS (

    SELECT
        stg_cleaned_micropayments.micropayment_id,
        cast(transaction_time AS TIMESTAMP) AS transaction_time,
        littlepay_transaction_id,
        cast(
            transaction_date_time_utc AS TIMESTAMP
        ) AS transaction_date_time_utc
    FROM stg_cleaned_micropayments
    INNER JOIN
        stg_cleaned_micropayment_device_transactions ON
            stg_cleaned_micropayments.micropayment_id = stg_cleaned_micropayment_device_transactions.micropayment_id
    INNER JOIN
        stg_cleaned_device_transactions USING (littlepay_transaction_id)
    WHERE
        cast(
            transaction_time AS TIMESTAMP
        ) < cast(transaction_date_time_utc AS TIMESTAMP)
)

SELECT * FROM validate_cleaned_micropayment_transaction_time_order
