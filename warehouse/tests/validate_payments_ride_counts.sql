{{ config(store_failures = true) }}

-- dst_table_name: "payments.invalid_payments_ride_counts"
-- Make sure that we did not lose any transactions while joining for the rides
-- table

--tests:
--  check_empty:
--    - "*"

WITH payments_rides_counts AS (
    SELECT
        'on' AS type,
        COUNTIF(charge_type = 'complete_variable_fare') AS val
    FROM views.payments_rides
    UNION ALL
    SELECT
        'off' AS type,
        COUNTIF(charge_type = 'complete_variable_fare') AS val
    FROM views.payments_rides
    UNION ALL
    SELECT
        'pending' AS type,
        COUNTIF(charge_type = 'pending_charge_fare') AS val
    FROM views.payments_rides
    UNION ALL
    SELECT
        'single' AS type,
        COUNTIF(charge_type = 'flat_fare') AS val
    FROM views.payments_rides
),

device_transaction_types_counts AS (
    SELECT
        'on' AS type,
        COUNTIF(transaction_type = 'on' AND NOT pending) AS val
    FROM payments.stg_cleaned_device_transaction_types
    UNION ALL
    SELECT
        'off' AS type,
        COUNTIF(transaction_type = 'off') AS val
    FROM payments.stg_cleaned_device_transaction_types
    UNION ALL
    SELECT
        'pending' AS type,
        COUNTIF(transaction_type = 'on' AND pending) AS val
    FROM payments.stg_cleaned_device_transaction_types
    UNION ALL
    SELECT
        'single' AS type,
        COUNTIF(transaction_type = 'single') AS val
    FROM payments.stg_cleaned_device_transaction_types
),

validate_payments_ride_counts AS (

    SELECT

        type AS transaction_type,
        p.val AS payments_rides_count,
        t.val AS device_transaction_types_count

    FROM payments_rides_counts AS p
    INNER JOIN device_transaction_types_counts AS t USING (type)
    WHERE p.val != t.val
)

SELECT * FROM validate_payments_ride_counts
