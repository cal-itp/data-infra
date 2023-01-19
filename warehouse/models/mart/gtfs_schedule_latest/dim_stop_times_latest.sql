WITH
dim_stop_times_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_stop_times'),
    clean_table_name = 'dim_stop_times'
    ) }}
)

SELECT * FROM dim_stop_times_latest
