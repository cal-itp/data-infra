{{ config(store_failures = true) }}

-- Tests that there is never a case where a settlement id is duplicated for both a refund
-- and a settlement.

-- Guards the dedup grain in int_payments__settlements_deduped, which collapses to one row
-- per (participant_id, settlement_id) and therefore assumes a settlement_id never spans more
-- than one settlement_type. If a sale (DEBIT) and its refund (CREDIT) ever shared a
-- settlement_id, that dedup would silently drop the refund.

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
