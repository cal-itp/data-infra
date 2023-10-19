WITH

micropayments_table_refunds AS (
    SELECT

        aggregation_id,
        micropayment_id,
        participant_id,
        customer_id,
        ABS(charge_amount) AS refund_amount,
        EXTRACT(DATE FROM transaction_time AT TIME ZONE "America/Los_Angeles") AS transaction_date,
        _line_number,
        SAFE_CAST(currency_code AS NUMERIC) AS currency_code,
        instance,
        extract_filename,
        ts,
        littlepay_export_ts,
        littlepay_export_date,
        _content_hash,
        _key,
        _payments_key,
        'micropayments' AS source_table

    FROM {{ ref('stg_littlepay__micropayments') }} WHERE type = 'CREDIT'
),

refunds_table_refunds AS (
    SELECT

        aggregation_id,
        micropayment_id,
        participant_id,
        customer_id,
        refund_amount,
        transaction_date,
        _line_number,
        currency_code,
        instance,
        extract_filename,
        ts,
        littlepay_export_ts,
        littlepay_export_date,
        _content_hash,
        _key,
        _payments_key,
        'refunds' AS source_table

    FROM {{ ref('stg_littlepay__refunds') }}
),

refunds_union AS (
    SELECT *
    FROM micropayments_table_refunds

    UNION ALL

    SELECT *
    FROM refunds_table_refunds
),

int_payments__refunds AS (

    SELECT

        aggregation_id,
        micropayment_id,
        participant_id,
        customer_id,
        refund_amount,
        transaction_date,
        _line_number,
        currency_code,
        instance,
        extract_filename,
        ts,
        littlepay_export_ts,
        littlepay_export_date,
        _content_hash,
        _key,
        _payments_key,
        source_table

    FROM refunds_union
)

SELECT * FROM int_payments__refunds
