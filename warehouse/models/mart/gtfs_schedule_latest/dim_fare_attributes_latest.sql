WITH
dim_fare_attributes_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_fare_attributes'),
    clean_table_name = 'dim_fare_attributions'
    ) }}
)

SELECT * FROM dim_fare_attributes_latest
