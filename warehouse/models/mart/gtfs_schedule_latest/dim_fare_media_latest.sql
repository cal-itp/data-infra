WITH
dim_fare_media_latest AS (
    {{ get_latest_schedule_data(
        table_name = ref('dim_fare_media'),
    clean_table_name = 'dim_fare_media'
        ) }}
)

SELECT * FROM dim_fare_media_latest
