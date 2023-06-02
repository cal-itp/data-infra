WITH
dim_fare_products_latest AS (
    {{ get_latest_schedule_data(
        table_name = ref('dim_fare_products'),
    clean_table_name = 'dim_fare_products'
        ) }}
)

SELECT * FROM dim_fare_products_latest
