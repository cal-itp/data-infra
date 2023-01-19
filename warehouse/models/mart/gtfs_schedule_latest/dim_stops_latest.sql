WITH
dim_stops_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_stops'),
    clean_table_name = 'dim_stops'
    ) }}
)

SELECT * FROM dim_stops_latest
