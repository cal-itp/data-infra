{{ config(materialized='table') }}

WITH calendar_clean AS (
    SELECT *
    FROM {{ ref('calendar_clean') }}
),
gtfs_schedule_stg_calendar_long AS (
    -- Note that you can unnest values easily in SQL, but getting the column names
    -- is weirdly hard. To work around this, we just UNION ALL.
    {% for dow in ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] %}

    {% if not loop.first %}
    UNION ALL
    {% endif %}

    SELECT
    calitp_itp_id
    , calitp_url_number
    , service_id
    , start_date
    , end_date
    , calitp_extracted_at
    , calitp_deleted_at
    , "{{dow | title}}" AS day_name
    , {{dow}} AS service_indicator
    FROM calendar_clean
    {% endfor %}
)

SELECT * FROM gtfs_schedule_stg_calendar_long
