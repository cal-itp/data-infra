-- Only participants that appear in the manually maintained device -> agency mapping can have
-- more than one organization behind a single Littlepay participant_id.
-- These participants should represent specifically regional agencies.
WITH device_mapped_participants AS (
    SELECT DISTINCT littlepay_participant_id AS participant_id
    FROM {{ ref('dim_payment_device_mapping') }}
),

rides AS (
    SELECT
        rides.aggregation_id,
        rides.organization_source_record_id,
        rides.transaction_date_time_utc,
        rides.littlepay_transaction_id
    FROM {{ ref('fct_payments_rides_v2') }} AS rides
    INNER JOIN device_mapped_participants
        USING (participant_id)
    WHERE rides.aggregation_id IS NOT NULL
        AND rides.transaction_date_time_utc IS NOT NULL
),

-- one row per aggregation: the agency (from the accurate device-level mapping) that
-- operated the earliest tap in the aggregation, keyed by transaction_date_time_utc.
-- littlepay_transaction_id breaks ties so the pick is deterministic when two taps in
-- the same aggregation share the earliest transaction_date_time_utc.
int_payments__regional_agencies_first_tap_by_aggregation AS (
    SELECT
        aggregation_id,
        ARRAY_AGG(
            organization_source_record_id
            ORDER BY transaction_date_time_utc, littlepay_transaction_id
            LIMIT 1
        )[SAFE_OFFSET(0)] AS first_tap_organization_source_record_id
    FROM rides
    GROUP BY aggregation_id
)

SELECT * FROM int_payments__regional_agencies_first_tap_by_aggregation
