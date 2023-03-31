WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'device_transactions') }}
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
         -- trim to align with gtfs cleaning steps
         -- since these fields are used to join with gtfs data
        TRIM(location_id) AS location_id,
        TRIM(route_id) AS route_id,
        location_scheme,
        location_name,
        zone_id,
        mode,
        direction,
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,
        ST_GEOGPOINT(CAST(longitude AS FLOAT64), CAST(latitude AS FLOAT64)) AS geography,
        vehicle_id,
        granted_zone_ids,
        onward_zone_ids,
        _line_number,
        `instance`,
        extract_filename,
        ts,
        littlepay_export_ts,
    FROM source
    QUALIFY ROW_NUMBER() OVER (PARTITION BY littlepay_transaction_id ORDER BY littlepay_export_ts DESC, transaction_date_time_utc DESC) = 1
)

SELECT * FROM stg_littlepay__device_transactions
