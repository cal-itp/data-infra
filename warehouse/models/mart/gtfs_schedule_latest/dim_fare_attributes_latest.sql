WITH
dim_fare_attributes_latest AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'fare_attributes',
    clean_table_name = ref('fare_attributes_clean')
    ) }}
)

SELECT * FROM dim_fare_attributes_latest
