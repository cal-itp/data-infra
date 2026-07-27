WITH settlements_unioned AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_settlements') }}
),

int_payments__settlements_deduped AS (
    SELECT
        *
    FROM settlements_unioned
    -- see: https://github.com/cal-itp/data-infra/issues/4552 and
    -- https://github.com/cal-itp/data-infra/issues/5584
    -- we have cases where same settlement comes in with two statuses
    -- only want to keep one instance -- the more recent one
    -- partition on settlement_id directly rather than on _payments_key: the staging
    -- _payments_key is generate_surrogate_key(['settlement_id', 'settlement_status']),
    -- so partitioning on it puts the PENDING and SETTLED versions of one settlement in
    -- separate partitions and both survive.
    -- transaction_amount is excluded because settlement_id is already the entity grain
    -- here: within one settlement_id the amount can only split versions of that single
    -- settlement, it can never separate two distinct settlements. (Contrast the second
    -- dedup in int_payments__refunds_deduped, where proposed_amount IS a partition key
    -- because that partition is aggregation-level and coarser than the entity ID.)
    -- Sales and their refunds are separate settlements with their own settlement_ids,
    -- so collapsing on settlement_id does not merge a DEBIT with its CREDIT.
    QUALIFY ROW_NUMBER() OVER
        (PARTITION BY participant_id, settlement_id
        ORDER BY record_updated_timestamp_utc DESC, littlepay_export_ts DESC, _line_number ASC) = 1
)

SELECT * FROM int_payments__settlements_deduped
