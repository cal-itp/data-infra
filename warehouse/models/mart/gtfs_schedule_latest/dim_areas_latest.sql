WITH
dim_areas_latest AS (
    {{ get_latest_schedule_data(
        table_name = ref('dim_areas'),
    clean_table_name = 'dim_areas'
        ) }}
)

SELECT * FROM dim_areas_latest
