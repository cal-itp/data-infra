WITH external_calendar AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'calendar') }}
),

stg_gtfs_schedule__calendar AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in external table definition

    SELECT
        base64_url,
        ts,
        {{ trim_make_empty_string_null('service_id') }} AS service_id,
        SAFE_CAST({{ trim_make_empty_string_null('monday') }} AS INTEGER) AS monday,
        SAFE_CAST({{ trim_make_empty_string_null('tuesday') }} AS INTEGER) AS tuesday,
        SAFE_CAST({{ trim_make_empty_string_null('wednesday') }} AS INTEGER) AS wednesday,
        SAFE_CAST({{ trim_make_empty_string_null('thursday') }} AS INTEGER) AS thursday,
        SAFE_CAST({{ trim_make_empty_string_null('friday') }} AS INTEGER) AS friday,
        SAFE_CAST({{ trim_make_empty_string_null('saturday') }} AS INTEGER) AS saturday,
        SAFE_CAST({{ trim_make_empty_string_null('sunday') }} AS INTEGER) AS sunday,
        PARSE_DATE("%Y%m%d", {{ trim_make_empty_string_null('start_date') }}) AS start_date,
        PARSE_DATE("%Y%m%d", {{ trim_make_empty_string_null('end_date') }}) AS end_date,
    FROM external_calendar
)

SELECT * FROM stg_gtfs_schedule__calendar
