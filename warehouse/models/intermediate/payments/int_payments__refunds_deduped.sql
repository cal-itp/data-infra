{{ config(materialized = "table") }}

WITH

micropayments_table_refunds AS (
    SELECT

        aggregation_id,
        micropayment_id,
        participant_id,
        customer_id,
        ABS(charge_amount) AS refund_amount,
        EXTRACT(DATE FROM transaction_time AT TIME ZONE "America/Los_Angeles") AS transaction_date,

        -- add columns that we want to preserve from refunds table after union as null strings
        SAFE_CAST(NULL AS STRING) AS refund_id,
        SAFE_CAST(NULL AS STRING) AS settlement_id,
        SAFE_CAST(NULL AS STRING) AS retrieval_reference_number,
        aggregation_id AS coalesced_id,
        SAFE_CAST(NULL AS NUMERIC) AS transaction_amount,
        SAFE_CAST(NULL AS NUMERIC) AS proposed_amount,
        SAFE_CAST(NULL AS STRING) AS status,
        SAFE_CAST(NULL AS STRING) AS initiator,
        SAFE_CAST(NULL AS STRING) AS reason,
        SAFE_CAST(NULL AS STRING) AS approval_status,
        SAFE_CAST(NULL AS STRING) AS issuer,
        SAFE_CAST(NULL AS STRING) AS issuer_comment,
        SAFE_CAST(NULL AS TIMESTAMP) AS created_time,
        SAFE_CAST(NULL AS TIMESTAMP) AS approved_time,
        SAFE_CAST(NULL AS STRING) AS settlement_status,
        SAFE_CAST(NULL AS DATE) AS settlement_status_time,
        SAFE_CAST(NULL AS STRING) AS settlement_reason_code,
        SAFE_CAST(NULL AS STRING) AS settlement_response_text,

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
        'micropayments' AS source_table

    FROM {{ ref('stg_littlepay__micropayments') }}
    WHERE type = 'CREDIT'
        -- these two refunds appear in both the micropayments and refund tables, and it was easier to
        -- drop them manually than make an overfit filter
        AND _key NOT IN ('043ecc000223a299ce17f6a342b1d240', '3536fb2035bbcf4dcb1f3abf001b5185')
),


distinct_aggregations_by_refund_id AS (

    SELECT DISTINCT retrieval_reference_number,
        aggregation_id
    FROM {{ ref('stg_littlepay__refunds') }}
    WHERE aggregation_id IS NOT NULL

),

refunds_table_refunds AS (
    SELECT

        COALESCE(t1.aggregation_id, t2.aggregation_id) as aggregation_id,
        micropayment_id,
        participant_id,
        customer_id,
        refund_amount,
        transaction_date,
        refund_id,
        settlement_id,
        retrieval_reference_number,
        COALESCE(retrieval_reference_number, t1.aggregation_id, t2.aggregation_id) AS coalesced_id,
        transaction_amount,
        proposed_amount,
        status,
        initiator,
        reason,
        approval_status,
        issuer,
        issuer_comment,
        created_time,
        approved_time,
        settlement_status,
        settlement_status_time,
        settlement_reason_code,
        settlement_response_text,
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

    FROM {{ ref('stg_littlepay__refunds') }} AS t1
    LEFT JOIN distinct_aggregations_by_refund_id AS t2
        USING (retrieval_reference_number)
    -- this dedupes on refund ID because individual refunds sometimes appear multiple times with multiple statuses
    -- the goal here is to get the latest update per refund
    QUALIFY DENSE_RANK() OVER (PARTITION BY refund_id ORDER BY littlepay_export_ts DESC) = 1

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
        refund_id,
        settlement_id,
        retrieval_reference_number,
        coalesced_id,
        transaction_amount,
        proposed_amount,
        status,
        initiator,
        reason,
        approval_status,
        issuer,
        issuer_comment,
        created_time,
        approved_time,
        settlement_status,
        settlement_status_time,
        settlement_reason_code,
        settlement_response_text,
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
    QUALIFY ROW_NUMBER() OVER (PARTITION BY coalesced_id, refund_amount ORDER BY littlepay_export_ts DESC) = 1

)

SELECT * FROM int_payments__refunds
