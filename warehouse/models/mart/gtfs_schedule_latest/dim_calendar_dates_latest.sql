WITH
dim_calendar_dates_latest AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'calendar_dates',
    clean_table_name = ref('calendar_dates_clean')
    ) }}
)

SELECT * FROM dim_calendar_dates_latest
