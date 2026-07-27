{{ config(store_failures = true) }}

-- Guards the dedup grain in int_payments__settlements_deduped, which collapses to one row
-- per (participant_id, settlement_id) and therefore assumes a settlement_id never spans more
-- than one settlement_type. If a sale (DEBIT) and its refund (CREDIT) ever shared a
-- settlement_id, that dedup would silently drop the refund.
--
-- This test deliberately runs against the dedup's INPUT rather than its output. The QUALIFY in
-- int_payments__settlements_deduped guarantees one row per settlement_id, so the uniqueness
-- test on that model would pass green even while a refund was being discarded -- the violation
-- is only observable upstream of the dedup.
--
-- settlement_type is nullable (fct_payments_settlements imputes it when missing), and a bare
-- COUNT(DISTINCT settlement_type) would skip those NULLs -- so a DEBIT row sharing a
-- settlement_id with an untyped refund would go unnoticed. NULL is therefore coalesced to a
-- sentinel and counted as its own type.
--
-- See https://github.com/cal-itp/data-infra/issues/5584 and, for the aggregation-grain
-- duplication that motivated the dedup in the first place, issue #4552.

WITH settlements_unioned AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_settlements') }}
),

bad_rows AS (
    SELECT
        participant_id,
        settlement_id,
        COUNT(*) AS num_rows,
        COUNT(DISTINCT COALESCE(settlement_type, '__MISSING__')) AS num_settlement_types,
        COUNT(DISTINCT settlement_type) AS num_non_null_settlement_types,
        COUNTIF(settlement_type IS NULL) AS num_untyped_rows,
        COUNT(DISTINCT settlement_status) AS num_settlement_statuses
    FROM settlements_unioned
    GROUP BY participant_id, settlement_id
    HAVING COUNT(DISTINCT COALESCE(settlement_type, '__MISSING__')) > 1
)

SELECT * FROM bad_rows
