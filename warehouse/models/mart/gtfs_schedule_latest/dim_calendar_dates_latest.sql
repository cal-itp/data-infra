WITH
dim_calendar_dates_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_calendar_dates'),
    clean_table_name = 'dim_calendar_dates'
    ) }}
)

SELECT * FROM dim_calendar_dates_latest
