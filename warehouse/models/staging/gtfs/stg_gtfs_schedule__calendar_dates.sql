WITH external_calendar_dates AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'calendar_dates') }}
),

stg_gtfs_schedule__calendar_dates AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in external table definition

    SELECT
        base64_url,
        ts,
        {{ trim_make_empty_string_null('service_id') }} AS service_id,
        PARSE_DATE("%Y%m%d", {{ trim_make_empty_string_null('date') }}) AS date,
        SAFE_CAST({{ trim_make_empty_string_null('exception_type') }} AS INTEGER) AS exception_type
    FROM external_calendar_dates
)

SELECT * FROM stg_gtfs_schedule__calendar_dates
