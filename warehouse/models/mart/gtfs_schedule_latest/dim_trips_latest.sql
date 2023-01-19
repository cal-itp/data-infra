WITH
dim_trips_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_trips'),
    clean_table_name = 'dim_trips'
    ) }}
)

SELECT * FROM dim_trips_latest
