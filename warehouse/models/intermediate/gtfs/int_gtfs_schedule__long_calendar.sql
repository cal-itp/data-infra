{{ config(materialized='table') }}

-- TODO: make an intermediate calendar and use that instead of the dimension
WITH dim_calendar AS (
    SELECT *
    FROM {{ ref('dim_calendar') }}
),

int_gtfs_schedule__long_calendar AS (
    -- Note that you can unnest values easily in SQL, but getting the column names
    -- is weirdly hard. To work around this, we just UNION ALL.
    {% for dow in ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] %}

        {% if not loop.first %}
            UNION ALL
        {% endif %}

        SELECT
            base64_url,
            feed_key,
            service_id,
            start_date,
            end_date,
            "{{ dow | title }}" AS day_name,
            CAST({{ dow }} AS boolean) AS service_indicator
        FROM dim_calendar
    {% endfor %}
)

SELECT *
FROM int_gtfs_schedule__long_calendar
