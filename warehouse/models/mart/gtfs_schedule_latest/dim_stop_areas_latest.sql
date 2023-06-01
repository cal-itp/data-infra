WITH
dim_stop_areas_latest AS (
    {{ get_latest_schedule_data(
        table_name = ref('dim_stop_areas'),
    clean_table_name = 'dim_stop_areas'
        ) }}
)

SELECT * FROM dim_stop_areas_latest
