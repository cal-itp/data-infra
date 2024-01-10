{{ config(materialized = 'table',) }}

WITH refunds AS (
    SELECT *
    FROM {{ ref('int_payments__refunds_deduped') }}
),

summarize_by_type AS (
    SELECT
        participant_id,
        aggregation_id,
        retrieval_reference_number,
        approval_status,
        SUM(proposed_amount) AS proposed_refund_amount,
    FROM refunds
    GROUP BY 1, 2, 3, 4
),

-- group again to get overall summary across types
summarize_overall AS (
    SELECT
        participant_id,
        aggregation_id,
        retrieval_reference_number,
        SUM(proposed_refund_amount) AS proposed_refund_amount,
    FROM summarize_by_type
    GROUP BY 1, 2, 3
),

int_payments__refunds_to_aggregations AS (
    SELECT
        summary.participant_id,
        summary.aggregation_id,
        summary.retrieval_reference_number,
        --should this be renamed?
        COALESCE(summary.proposed_refund_amount,0) AS total_refund_activity_amount_dollars,
        COALESCE(approved.proposed_refund_amount,0) AS approved_amount,
        COALESCE(refused.proposed_refund_amount,0) AS refused_amount,
        COALESCE(awaiting.proposed_refund_amount,0) AS awaiting_amount,
        COALESCE(null_approval_status.proposed_refund_amount,0) AS null_approval_status_amount
    FROM summarize_overall AS summary
    LEFT JOIN summarize_by_type AS approved
        ON summary.aggregation_id = approved.aggregation_id
        AND summary.retrieval_reference_number = approved.retrieval_reference_number
        AND approved.approval_status = "APPROVED"
    LEFT JOIN summarize_by_type AS refused
        ON summary.aggregation_id = refused.aggregation_id
        AND summary.retrieval_reference_number = refused.retrieval_reference_number
        AND refused.approval_status = "REFUSED"
    LEFT JOIN summarize_by_type AS awaiting
        ON summary.aggregation_id = awaiting.aggregation_id
        AND summary.retrieval_reference_number = awaiting.retrieval_reference_number
        AND awaiting.approval_status = "AWAITING"
    -- should this be kept, to track null approval status amounts?
    LEFT JOIN summarize_by_type AS null_approval_status
        ON summary.aggregation_id = null_approval_status.aggregation_id
        AND summary.retrieval_reference_number = null_approval_status.retrieval_reference_number
        AND null_approval_status.approval_status IS NULL
)

SELECT * FROM int_payments__refunds_to_aggregations
