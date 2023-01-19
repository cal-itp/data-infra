WITH
dim_feed_info_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_feed_info'),
    clean_table_name = 'dim_feed_info'
    ) }}
)

SELECT * FROM dim_feed_info_latest
