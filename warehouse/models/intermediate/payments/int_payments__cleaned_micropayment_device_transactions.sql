{{
  config(
    materialized = 'table',
    )
}}

WITH int_littlepay__unioned_micropayment_device_transactions AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_micropayment_device_transactions') }}
),

int_littlepay__unioned_micropayments AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_micropayments') }}
),

deduped_micropayment_device_transaction_ids AS (
    SELECT DISTINCT

        littlepay_transaction_id,
        micropayment_id
    FROM int_littlepay__unioned_micropayment_device_transactions
),

join_transactions_to_micropayments AS (
    SELECT DISTINCT
        littlepay_transaction_id,
        micropayment_id,
        charge_type,
        type,
    FROM deduped_micropayment_device_transaction_ids
    INNER JOIN int_littlepay__unioned_micropayments
        USING(micropayment_id)
),

-- Some transactions are associated with more than one DEBIT micropayment. This
-- should not happen. In the query below, we identify the micropayment_id of the
-- pending micropayment records that are no longer valid because they've been
-- superceded by a completed micropayment.
--
-- See https://github.com/cal-itp/data-infra/ISsues/647 for the explanation.
invalid_micropayment_device_transaction_ids AS (
    SELECT
        first_transaction.littlepay_transaction_id,
        first_transaction.micropayment_id
    FROM join_transactions_to_micropayments AS first_transaction
    INNER JOIN deduped_micropayment_device_transaction_ids AS second_micropayment_device_transaction
        USING (littlepay_transaction_id)
    INNER JOIN int_littlepay__unioned_micropayments AS second_micropayment
        ON second_micropayment_device_transaction.micropayment_id = second_micropayment.micropayment_id
    WHERE first_transaction.micropayment_id != second_micropayment.micropayment_id
        AND first_transaction.charge_type = 'pending_charge_fare'
        AND second_micropayment.charge_type = 'complete_variable_fare'
),

cleaned_micropayment_device_transaction_ids AS (
    SELECT
        littlepay_transaction_id,
        micropayment_id,
        charge_type AS micropayment_charge_type,
        type AS micropayment_type,
    FROM deduped_micropayment_device_transaction_ids
    LEFT JOIN invalid_micropayment_device_transaction_ids AS invalid
        USING (littlepay_transaction_id, micropayment_id)
    LEFT JOIN join_transactions_to_micropayments
        USING (littlepay_transaction_id, micropayment_id)
    WHERE invalid.littlepay_transaction_id IS null
),

int_payments__cleaned_micropayment_device_transactions AS (

    SELECT DISTINCT *
    FROM int_littlepay__unioned_micropayment_device_transactions
    INNER JOIN cleaned_micropayment_device_transaction_ids
        USING (littlepay_transaction_id, micropayment_id)
)

SELECT * FROM int_payments__cleaned_micropayment_device_transactions
