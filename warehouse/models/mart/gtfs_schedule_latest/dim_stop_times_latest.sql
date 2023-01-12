WITH
dim_stop_times_latest AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'stop_times',
    clean_table_name = ref('stop_times_clean')
    ) }}
)

SELECT * FROM dim_stop_times_latest
