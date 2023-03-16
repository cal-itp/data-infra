WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'device_transactions') }}
),

stg_littlepay__device_transactions AS (
    SELECT
        participant_id,
        customer_id,
        device_transaction_id,
        littlepay_transaction_id,
        device_id,
        device_id_issuer,
        type,
        transaction_outcome,
        transction_deny_reason,
        transaction_date_time_utc,
        DATETIME(
            TIMESTAMP(transaction_date_time_utc), "America/Los_Angeles"
        ) AS transaction_date_time_pacific,
        location_id,
        location_scheme,
        location_name,
        zone_id,
        route_id,
        mode,
        direction,
        latitude,
        longitude,
        vehicle_id,
        granted_zone_ids,
        onward_zone_ids,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__device_transactions
