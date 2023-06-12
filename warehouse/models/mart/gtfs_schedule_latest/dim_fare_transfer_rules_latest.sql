WITH
dim_fare_transfer_rules_latest AS (
    {{ get_latest_schedule_data(
        table_name = ref('dim_fare_transfer_rules'),
    clean_table_name = 'dim_fare_transfer_rules'
        ) }}
)

SELECT * FROM dim_fare_transfer_rules_latest
