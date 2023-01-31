WITH external_translations AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'translations') }}
),

stg_gtfs_schedule__translations AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition


    SELECT
        base64_url,
        ts,
        dt AS _dt,
        {{ trim_make_empty_string_null('table_name') }} AS table_name,
        {{ trim_make_empty_string_null('field_name') }} AS field_name,
        {{ trim_make_empty_string_null('language') }} AS language,
        {{ trim_make_empty_string_null('translation') }} AS translation,
        {{ trim_make_empty_string_null('record_id') }} AS record_id,
        {{ trim_make_empty_string_null('record_sub_id') }} AS record_sub_id,
        {{ trim_make_empty_string_null('field_value') }} AS field_value
    FROM external_translations
)

SELECT * FROM stg_gtfs_schedule__translations
