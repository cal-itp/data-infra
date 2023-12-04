{{ config(materialized = "table") }}

WITH micropayment_device_transactions AS (
    SELECT * FROM {{ ref('int_payments__cleaned_micropayment_device_transactions') }}
),

micropayments_refunds AS (
    SELECT * FROM {{ ref('stg_littlepay__micropayments') }}
    WHERE type = 'CREDIT'
),

refunds AS (
    SELECT * FROM {{ ref('stg_littlepay__refunds') }}
),

format_micropayments_table_refunds AS (
    SELECT

        micropayments_refunds.aggregation_id,
        -- in the refunds table, the micropayment ID is the ID of the micropayment *being refunded*
        -- in the micropayments refunds, the refund has a separate micropayment ID
        -- so we look up the micropayment ID of the micropayment being refunded rather than using the micropayment ID of the refund
        debit.micropayment_id,
        micropayments_refunds.participant_id,
        micropayments_refunds.customer_id,
        ABS(micropayments_refunds.charge_amount) AS proposed_amount,
        EXTRACT(DATE FROM micropayments_refunds.transaction_time) AS transaction_date,
        micropayments_refunds.aggregation_id AS coalesced_id,

        -- add columns that we want to preserve from refunds table after union as null strings
        SAFE_CAST(NULL AS NUMERIC) AS refund_amount,
        SAFE_CAST(NULL AS STRING) AS refund_id,
        SAFE_CAST(NULL AS STRING) AS settlement_id,
        SAFE_CAST(NULL AS STRING) AS retrieval_reference_number,
        SAFE_CAST(NULL AS NUMERIC) AS transaction_amount,
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

        micropayments_refunds._line_number,
        micropayments_refunds.currency_code,
        micropayments_refunds.instance,
        micropayments_refunds.extract_filename,
        micropayments_refunds.ts,
        micropayments_refunds.littlepay_export_ts,
        micropayments_refunds.littlepay_export_date,
        micropayments_refunds._content_hash,
        micropayments_refunds._key,
        micropayments_refunds._payments_key,
        'micropayments' AS source_table

    FROM micropayments_refunds
    LEFT JOIN micropayment_device_transactions AS credit
        ON micropayments_refunds.micropayment_id = credit.micropayment_id
    LEFT JOIN micropayment_device_transactions AS debit
        ON debit.littlepay_transaction_id = credit.littlepay_transaction_id
        AND debit.micropayment_id != credit.micropayment_id
        -- there's one of these that has a stray extra $0 charge mixed in which messes up the mappings
        AND debit._key != 'e32be429e135e6df8d3d3fd45f6ecf89'
    -- these two refunds appear in both the micropayments and refund tables, and it was easier to
    -- drop them manually than make an overfit filter
    WHERE micropayments_refunds._key NOT IN ('043ecc000223a299ce17f6a342b1d240', '3536fb2035bbcf4dcb1f3abf001b5185')
),


distinct_aggregations_by_refund_id AS (

    SELECT DISTINCT retrieval_reference_number,
        aggregation_id
    FROM {{ ref('stg_littlepay__refunds') }}
    WHERE aggregation_id IS NOT NULL

),

format_refunds_table_refunds AS (
    SELECT

        COALESCE(t1.aggregation_id, t2.aggregation_id) as aggregation_id,
        micropayment_id,
        participant_id,
        customer_id,
        proposed_amount,
        transaction_date,
        COALESCE(retrieval_reference_number, t1.aggregation_id, t2.aggregation_id) AS coalesced_id,
        refund_amount,
        refund_id,
        settlement_id,
        retrieval_reference_number,
        transaction_amount,
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

    FROM refunds AS t1
    LEFT JOIN distinct_aggregations_by_refund_id AS t2
        USING (retrieval_reference_number)
    -- this dedupes on refund ID because individual refunds sometimes appear multiple times with multiple statuses
    -- the goal here is to get the latest update per refund
    QUALIFY DENSE_RANK() OVER (PARTITION BY refund_id ORDER BY littlepay_export_ts DESC) = 1
),

refunds_union AS (
    SELECT *
    FROM format_micropayments_table_refunds

    UNION ALL

    SELECT *
    FROM format_refunds_table_refunds
),

-- in addition to the qualify statement above, we have an issue where some refunds are initially refused and then later approved
-- but they get a new refund ID generated
-- address that thus
next_status AS (
  SELECT
    participant_id,
    refund_id,
    aggregation_id,
    LEAD(approval_status) OVER(PARTITION BY participant_id, micropayment_id ORDER BY created_time ASC) AS next_approval_status,
    approval_status
  FROM refunds_union
),

to_drop AS (
  SELECT DISTINCT participant_id, refund_id
  FROM next_status
  WHERE approval_status = "REFUSED" AND next_approval_status = "APPROVED"
),

int_payments__refunds AS (

    SELECT

        aggregation_id,
        micropayment_id,
        participant_id,
        customer_id,
        proposed_amount,
        transaction_date,
        coalesced_id,
        refund_amount,
        refund_id,
        settlement_id,
        retrieval_reference_number,
        transaction_amount,
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
    LEFT JOIN to_drop USING (participant_id, refund_id)
    WHERE to_drop.refund_id IS NULL
    -- this dedupes on coalesced_id (which is comprised of retrieval_reference_number or aggregation_id if it is null) and refund_amount
    -- because we observe some duplicate refunds by retrieval_reference_number/aggregation_id and refund_amount
    -- add line number to sorting to make this deterministic
    QUALIFY ROW_NUMBER() OVER (PARTITION BY coalesced_id, refund_amount ORDER BY littlepay_export_ts DESC, _line_number DESC) = 1

)

SELECT * FROM int_payments__refunds
