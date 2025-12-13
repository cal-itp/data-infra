{{ config(materialized = "table") }}

WITH micropayment_device_transactions AS (
    SELECT * FROM {{ ref('int_payments__cleaned_micropayment_device_transactions') }}
),

micropayments_refunds AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_micropayments') }}
    WHERE type = 'CREDIT'
),

refunds AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_refunds') }}
),

-- in the refunds table, the micropayment ID is the ID of the micropayment *being refunded*
-- in the micropayments refunds, the refund has a separate micropayment ID
-- so we have to look up the micropayment ID of the micropayment being refunded rather than using the micropayment ID of the refund
micropayment_refund_id_lookup AS (
    SELECT
        micropayments_refunds.aggregation_id,
        debit.micropayment_id,
        micropayments_refunds.participant_id,
        micropayments_refunds.customer_id,
        EXTRACT(DATE FROM micropayments_refunds.transaction_time) AS transaction_date,
        micropayments_refunds.aggregation_id AS coalesced_id,
        ABS(micropayments_refunds.charge_amount) AS refund_amount,
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
    -- have to do a two step join to find the original "debit" micropayment that is being refunded
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

-- prepare refunds table to be combined with micropayments
-- start with trying to populate aggregation_id where missing
distinct_aggregations_by_refund_id AS (
    SELECT DISTINCT retrieval_reference_number,
        aggregation_id
    FROM {{ ref('int_littlepay__unioned_refunds') }}
    WHERE aggregation_id IS NOT NULL
),

-- also dedupe when same refund appears multiple times
refunds_populate_aggregation_id_dedupe_over_status AS (
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

-- in addition to the qualify statement above, we have an issue where some refunds are initially refused and then later approved
-- but they get a new refund ID generated
refunds_next_status AS (
  SELECT
    participant_id,
    refund_id,
    aggregation_id,
    LEAD(approval_status) OVER(PARTITION BY participant_id, micropayment_id ORDER BY created_time ASC) AS next_approval_status,
    approval_status
  FROM refunds_populate_aggregation_id_dedupe_over_status
),

refunds_refused_then_approved AS (
  SELECT DISTINCT participant_id, refund_id
  FROM refunds_next_status
  WHERE approval_status = "REFUSED" AND next_approval_status = "APPROVED"
),

-- remove the refused then approved refunds as well as other remaining duplicates
refunds_remove_refused_then_approved_and_remaining_dups AS (
    SELECT *
    FROM refunds_populate_aggregation_id_dedupe_over_status
    LEFT JOIN refunds_refused_then_approved USING (participant_id, refund_id)
    WHERE refunds_refused_then_approved.refund_id IS NULL
    -- this dedupes on coalesced_id (which is comprised of retrieval_reference_number or aggregation_id if it is null), micropayment_id, and refund_amount
    -- because we observe some duplicate refunds
    -- use line number in sorting to make this deterministic
    QUALIFY ROW_NUMBER() OVER (PARTITION BY coalesced_id, COALESCE(micropayment_id, '0'), proposed_amount ORDER BY littlepay_export_ts DESC, _line_number DESC) = 1
),

combine_micropayments_and_refunds AS (
    SELECT
        COALESCE(refunds.aggregation_id, micropayments.aggregation_id) AS aggregation_id,
        COALESCE(refunds.micropayment_id, micropayments.micropayment_id) AS micropayment_id,
        COALESCE(refunds.participant_id, micropayments.participant_id) AS participant_id,
        COALESCE(refunds.customer_id, micropayments.customer_id) AS customer_id,
        refunds.proposed_amount AS refund_proposed_amount,
        COALESCE(refunds.transaction_date, micropayments.transaction_date) AS transaction_date,
        COALESCE(refunds.coalesced_id, micropayments.coalesced_id) AS coalesced_id,
        COALESCE(refunds.refund_amount, micropayments.refund_amount) AS refund_amount,
        -- keep micropayments refund amount as a separate column to test that if both were present the values were the same
        micropayments.refund_amount AS micropayments_refund_amount,
        refunds.refund_id,
        refunds.proposed_amount,
        refunds.settlement_id AS settlement_id,
        refunds.retrieval_reference_number,
        refunds.transaction_amount,
        refunds.status,
        refunds.initiator,
        refunds.reason,
        refunds.approval_status,
        refunds.issuer,
        refunds.issuer_comment,
        refunds.created_time,
        refunds.approved_time,
        refunds.settlement_status,
        refunds.settlement_status_time,
        refunds.settlement_reason_code,
        refunds.settlement_response_text,

        -- metadata
        refunds._line_number AS refunds_line_number,
        refunds.currency_code AS refunds_currency_code,
        refunds.instance AS refunds_instance,
        refunds.extract_filename AS refunds_extract_filename,
        refunds.ts AS refunds_ts,
        refunds.littlepay_export_ts AS refunds_littlepay_export_ts,
        refunds.littlepay_export_date AS refunds_littlepay_export_date,
        refunds._content_hash AS refunds_content_hash,
        refunds._key AS refunds_key,
        refunds._payments_key AS refunds_payments_key,

        micropayments._line_number AS micropayments_line_number,
        micropayments.currency_code AS micropayments_currency_code,
        micropayments.instance AS micropayments_instance,
        micropayments.extract_filename AS micropayments_extract_filename,
        micropayments.ts AS micropayments_ts,
        micropayments.littlepay_export_ts AS micropayments_littlepay_export_ts,
        micropayments.littlepay_export_date AS micropayments_littlepay_export_date,
        micropayments._content_hash AS micropayments_content_hash,
        micropayments._key AS micropayments_key,
        micropayments._payments_key AS micropayments_payments_key,

        CASE
            WHEN refunds.source_table IS NOT NULL AND micropayments.source_table IS NOT NULL THEN "both_refunds_and_micropayments"
            ELSE COALESCE(refunds.source_table, micropayments.source_table)
        END AS source_table
    FROM refunds_remove_refused_then_approved_and_remaining_dups AS refunds
    FULL OUTER JOIN micropayment_refund_id_lookup AS micropayments
    ON refunds.micropayment_id = micropayments.micropayment_id
),

int_payments__refunds_deduped AS (
    SELECT
        aggregation_id,
        micropayment_id,
        participant_id,
        customer_id,
        proposed_amount,
        transaction_date,
        coalesced_id,
        refund_amount,
        micropayments_refund_amount,
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

        refunds_line_number,
        refunds_currency_code,
        refunds_instance,
        refunds_extract_filename,
        refunds_ts,
        refunds_littlepay_export_ts,
        refunds_littlepay_export_date,
        refunds_content_hash,
        refunds_key,
        refunds_payments_key,

        micropayments_line_number,
        micropayments_currency_code,
        micropayments_instance,
        micropayments_extract_filename,
        micropayments_ts,
        micropayments_littlepay_export_ts,
        micropayments_littlepay_export_date,
        micropayments_content_hash,
        micropayments_key,
        micropayments_payments_key,
        source_table
    FROM combine_micropayments_and_refunds
)

SELECT * FROM int_payments__refunds_deduped
