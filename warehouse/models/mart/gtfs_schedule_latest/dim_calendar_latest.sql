WITH
dim_calendar_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_calendar')
    ) }}
)

SELECT * FROM dim_calendar_latest
