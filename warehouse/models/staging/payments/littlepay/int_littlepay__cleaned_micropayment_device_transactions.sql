WITH stg_littlepay__micropayment_device_transactions AS (
    SELECT * FROM {{ ref('stg_littlepay__micropayment_device_transactions') }}
),

stg_littlepay__micropayments AS (
    SELECT * FROM {{ ref('stg_littlepay__micropayments') }}
),

deduped_micropayment_device_transaction_ids AS (
    SELECT DISTINCT
        littlepay_transaction_id,
        micropayment_id
    FROM stg_littlepay__micropayment_device_transactions
),

-- Some transactions are associated with more than one DEBIT micropayment. This
-- should not happen. In the query below, we identify the micropayment_id of the
-- pending micropayment records that are no longer valid because they've been
-- superceded by a completed micropayment.
--
-- See https://github.com/cal-itp/data-infra/ISsues/647 for the explanation.
invalid_micropayment_device_transaction_ids AS (
    SELECT
        littlepay_transaction_id,
        first_micropayment.micropayment_id

    FROM deduped_micropayment_device_transaction_ids AS micropayment_device_transaction
    INNER JOIN stg_littlepay__micropayments AS first_micropayment
        ON micropayment_device_transaction.micropayment_id = first_micropayment.micropayment_id

    INNER JOIN deduped_micropayment_device_transaction_ids AS second_micropayment_device_transaction USING (littlepay_transaction_id)
    INNER JOIN stg_littlepay__micropayments AS second_micropayment
        ON second_micropayment_device_transaction.micropayment_id = second_micropayment.micropayment_id

    WHERE first_micropayment.micropayment_id != second_micropayment.micropayment_id
        AND first_micropayment.charge_type = 'pending_charge_fare'
        AND second_micropayment.charge_type = 'complete_variable_fare'
),

cleaned_micropayment_device_transaction_ids AS (
    SELECT
        littlepay_transaction_id,
        micropayment_id
    FROM deduped_micropayment_device_transaction_ids
    LEFT JOIN invalid_micropayment_device_transaction_ids AS invalid
        USING (littlepay_transaction_id, micropayment_id)
    WHERE invalid.littlepay_transaction_id IS null
),

int_littlepay__cleaned_micropayment_device_transactions AS (

    SELECT DISTINCT *
    FROM stg_littlepay__micropayment_device_transactions
    INNER JOIN cleaned_micropayment_device_transaction_ids
        USING (littlepay_transaction_id, micropayment_id)
)

SELECT * FROM int_littlepay__cleaned_micropayment_device_transactions
