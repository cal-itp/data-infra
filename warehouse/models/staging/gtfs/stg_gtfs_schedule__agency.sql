WITH external_agency AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'agency') }}
),

stg_gtfs_schedule__agency AS (
    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        _line_number,
        {{ trim_make_empty_string_null('agency_id') }} AS agency_id,
        {{ trim_make_empty_string_null('agency_name') }} AS agency_name,
        {{ trim_make_empty_string_null('agency_url') }} AS agency_url,
        -- timezone is passed directly to BigQuery date/time functions later so we may need to add validation
        -- if we ever encounter an invalid value here
        {{ trim_make_empty_string_null('agency_timezone') }} AS agency_timezone,
        {{ trim_make_empty_string_null('agency_lang') }} AS agency_lang,
        {{ trim_make_empty_string_null('agency_phone') }} AS agency_phone,
        {{ trim_make_empty_string_null('agency_fare_url') }} AS agency_fare_url,
        {{ trim_make_empty_string_null('agency_email') }} AS agency_email,
    FROM external_agency
)

SELECT * FROM stg_gtfs_schedule__agency
