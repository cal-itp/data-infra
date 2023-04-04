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
        {{ trim_make_empty_string_null('agency_id') }} AS agency_id,
        {{ trim_make_empty_string_null('agency_name') }} AS agency_name,
        {{ trim_make_empty_string_null('agency_url') }} AS agency_url,
        {{ trim_make_empty_string_null('agency_timezone') }} AS agency_timezone,
        {{ trim_make_empty_string_null('agency_lang') }} AS agency_lang,
        {{ trim_make_empty_string_null('agency_phone') }} AS agency_phone,
        {{ trim_make_empty_string_null('agency_fare_url') }} AS agency_fare_url,
        {{ trim_make_empty_string_null('agency_email') }} AS agency_email,
        -- enumerate the values that we have encountered in this field
        -- confirm that they work in BigQuery, i.e., they can be passed to the TIMESTAMP function and do not return an error
        CASE
            WHEN {{ trim_make_empty_string_null('agency_timezone') }} IN ('America/Los_Angeles', 'US/Pacific', 'America/Vancouver',
                'America/New_York', 'Canada/Pacific', 'America/Phoenix', 'PST8PDT') THEN agency_timezone
        END AS agency_timezone_valid_tz
    FROM external_agency
)

SELECT * FROM stg_gtfs_schedule__agency
