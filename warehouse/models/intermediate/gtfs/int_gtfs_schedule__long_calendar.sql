-- TODO: make an intermediate calendar and use that instead of the dimension
WITH dim_calendar AS (
    SELECT *
    FROM {{ ref('dim_calendar') }}
),

-- TODO: see if this can be refactored using UNPIVOT (logic inherited from v1 warehouse, wondering if it should be revisited)
int_gtfs_schedule__long_calendar AS (
    -- Note that you can unnest values easily in SQL, but getting the column names
    -- is weirdly hard. To work around this, we just UNION ALL.
    {% for dow in [("monday", 2), ("tuesday", 3), ("wednesday", 4), ("thursday", 5), ("friday", 6), ("saturday", 7), ("sunday", 0)] %}

        {% if not loop.first %}
            UNION ALL
        {% endif %}

        SELECT
            base64_url,
            key AS calendar_key,
            feed_key,
            service_id,
            start_date,
            end_date,
            "{{ dow[0] }}" AS day_name,
            {{ dow[1] }} AS day_num,
            CAST({{ dow[0] }} AS boolean) AS has_service
        FROM dim_calendar
    {% endfor %}
)

SELECT *
FROM int_gtfs_schedule__long_calendar
