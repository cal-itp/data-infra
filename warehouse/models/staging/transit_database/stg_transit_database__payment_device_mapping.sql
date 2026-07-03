WITH

once_daily_payment_device_mapping AS (
    SELECT *
    FROM {{ ref('base_tts_payment_device_mapping_idmap') }}
),

stg_transit_database__payment_device_mapping AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "device_id") }} AS device_id,
        littlepay_participant_id,
        agency[SAFE_OFFSET(0)] AS agency_organization_source_record_id,
        agency_name[SAFE_OFFSET(0)] AS agency_name,
        notes,
        start_date,
        end_date,
        status,
        dt
    FROM once_daily_payment_device_mapping
)

SELECT * FROM stg_transit_database__payment_device_mapping
