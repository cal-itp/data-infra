WITH int_payments__matched_device_transactions AS (
    SELECT
        littlepay_transaction_id,
        off_littlepay_transaction_id,
        micropayment_id,
        micropayment_type,
        participant_id,
        route_id,
        direction,
        vehicle_id,
        device_id,
        transaction_type,
        transaction_outcome,
        transaction_date_time_utc,
        transaction_date_time_pacific,
        location_id,
        location_name,
        latitude,
        longitude,
        on_latitude,
        on_longitude,
        on_geography,
        off_device_id,
        off_transaction_type,
        off_transaction_outcome,
        off_transaction_date_time_utc,
        off_transaction_date_time_pacific,
        off_location_id,
        off_location_name,
        off_latitude,
        off_longitude,
        off_geography,
        duration,
        distance_meters,
        transaction_date_pacific,
        day_of_week,
        distance_miles
    FROM {{ ref('int_payments__matched_device_transactions') }}
),

dim_payment_device_mapping AS (
    SELECT
        littlepay_participant_id,
        device_id,
        agency_organization_source_record_id,
        start_date,
        end_date
    FROM {{ ref('dim_payment_device_mapping') }}
),

payments_entity_mapping AS (
    SELECT
        littlepay_participant_id,
        organization_source_record_id,
        _in_use_from,
        _in_use_until
    FROM {{ ref('payments_entity_mapping') }}
),

-- Resolve the operating agency for each device transaction. First try the manually maintained
-- device -> agency mapping, which disambiguates agencies that share a Littlepay participant_id
-- (e.g. SLORTA / SLO City) by matching on participant_id, device_id, and the transaction date
-- falling within the mapping's assignment window (start_date / end_date, either of which may be
-- open-ended). For transactions with no device-level mapping, fall back to the participant-level
-- payments_entity_mapping seed (the same seed the payments marts use), matching on participant_id
-- and the transaction time falling within the seed's in-use window.
int_payments__agency_joined_device_transactions AS (
    SELECT
        device_transactions.*,
        COALESCE(
            device_mapping.agency_organization_source_record_id,
            entity_mapping.organization_source_record_id
        ) AS organization_source_record_id,
    FROM int_payments__matched_device_transactions AS device_transactions
    LEFT JOIN dim_payment_device_mapping AS device_mapping
        ON device_transactions.participant_id = device_mapping.littlepay_participant_id
        AND device_transactions.device_id = device_mapping.device_id
        AND (device_transactions.transaction_date_pacific >= device_mapping.start_date)
        AND (device_transactions.transaction_date_pacific <= device_mapping.end_date)
    LEFT JOIN payments_entity_mapping AS entity_mapping
        ON device_transactions.participant_id = entity_mapping.littlepay_participant_id
        AND CAST(device_transactions.transaction_date_time_utc AS TIMESTAMP)
            BETWEEN CAST(entity_mapping._in_use_from AS TIMESTAMP)
            AND CAST(entity_mapping._in_use_until AS TIMESTAMP)
)

SELECT
    littlepay_transaction_id,
    off_littlepay_transaction_id,
    micropayment_id,
    micropayment_type,
    participant_id,
    organization_source_record_id,
    route_id,
    direction,
    vehicle_id,
    device_id,
    transaction_type,
    transaction_outcome,
    transaction_date_time_utc,
    transaction_date_time_pacific,
    location_id,
    location_name,
    latitude,
    longitude,
    on_latitude,
    on_longitude,
    on_geography,
    off_device_id,
    off_transaction_type,
    off_transaction_outcome,
    off_transaction_date_time_utc,
    off_transaction_date_time_pacific,
    off_location_id,
    off_location_name,
    off_latitude,
    off_longitude,
    off_geography,
    duration,
    distance_meters,
    transaction_date_pacific,
    day_of_week,
    distance_miles
FROM int_payments__agency_joined_device_transactions
