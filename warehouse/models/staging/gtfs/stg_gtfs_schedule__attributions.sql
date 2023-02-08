WITH external_attributions AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'attributions') }}
),

stg_gtfs_schedule__attributions AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    SELECT
        base64_url,
        ts,
        dt AS _dt,
        {{ trim_make_empty_string_null('organization_name') }} AS organization_name,
        {{ trim_make_empty_string_null('attribution_id') }} AS attribution_id,
        {{ trim_make_empty_string_null('agency_id') }} AS agency_id,
        {{ trim_make_empty_string_null('route_id') }} AS route_id,
        {{ trim_make_empty_string_null('trip_id') }} AS trip_id,
        SAFE_CAST({{ trim_make_empty_string_null('is_producer') }} AS INTEGER) AS is_producer,
        SAFE_CAST({{ trim_make_empty_string_null('is_operator') }} AS INTEGER) AS is_operator,
        SAFE_CAST({{ trim_make_empty_string_null('is_authority') }} AS INTEGER) AS is_authority,
        {{ trim_make_empty_string_null('attribution_url') }} AS attribution_url,
        {{ trim_make_empty_string_null('attribution_email') }} AS attribution_email,
        {{ trim_make_empty_string_null('attribution_phone') }} AS attribution_phone
    FROM external_attributions
)

SELECT * FROM stg_gtfs_schedule__attributions
