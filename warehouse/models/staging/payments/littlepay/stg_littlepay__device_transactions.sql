WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'device_transactions') }}
),

stg_littlepay__device_transactions AS (
    SELECT
        {{ trim_make_empty_string_null('participant_id') }} AS participant_id,
        {{ trim_make_empty_string_null('customer_id') }} AS customer_id,
        {{ trim_make_empty_string_null('device_transaction_id') }} AS device_transaction_id,
        {{ trim_make_empty_string_null('littlepay_transaction_id') }} AS littlepay_transaction_id,
        {{ trim_make_empty_string_null('device_id') }} AS device_id,
        {{ trim_make_empty_string_null('device_id_issuer') }} AS device_id_issuer,
        {{ trim_make_empty_string_null('type') }} AS type,
        {{ trim_make_empty_string_null('transaction_outcome') }} AS transaction_outcome,
        {{ trim_make_empty_string_null('transction_deny_reason') }} AS transction_deny_reason,
        {{ trim_make_empty_string_null('transaction_date_time_utc') }} AS transaction_date_time_utc,
        DATETIME(
            TIMESTAMP(transaction_date_time_utc), "America/Los_Angeles"
        ) AS transaction_date_time_pacific,
         -- trim to align with gtfs cleaning steps
         -- since these fields are used to join with gtfs data
        {{ trim_make_empty_string_null('location_id') }} AS location_id,
        {{ trim_make_empty_string_null('route_id') }} AS route_id,
        {{ trim_make_empty_string_null('location_scheme') }} AS location_scheme,
        {{ trim_make_empty_string_null('location_name') }} AS location_name,
        {{ trim_make_empty_string_null('zone_id') }} AS zone_id,
        {{ trim_make_empty_string_null('mode') }} AS mode,
        {{ trim_make_empty_string_null('direction') }} AS direction,
        CAST(latitude AS NUMERIC) AS latitude,
        CAST(longitude AS NUMERIC) AS longitude,
        ST_GEOGPOINT(CAST(longitude AS NUMERIC), CAST(latitude AS NUMERIC)) AS geography,
        {{ trim_make_empty_string_null('vehicle_id') }} AS vehicle_id,
        {{ trim_make_empty_string_null('granted_zone_ids') }} AS granted_zone_ids,
        {{ trim_make_empty_string_null('onward_zone_ids') }} AS onward_zone_ids,
        _line_number,
        `instance`,
        extract_filename,
        ts,
        littlepay_export_ts,
    FROM source
    QUALIFY ROW_NUMBER() OVER (PARTITION BY littlepay_transaction_id ORDER BY littlepay_export_ts DESC, transaction_date_time_utc DESC) = 1
)

SELECT * FROM stg_littlepay__device_transactions
