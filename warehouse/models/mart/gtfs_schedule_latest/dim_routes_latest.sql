WITH
dim_routes_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_routes'),
    clean_table_name = 'dim_routes'
    ) }}
)

SELECT * FROM dim_routes_latest
