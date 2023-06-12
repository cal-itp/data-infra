WITH
dim_fare_leg_rules_latest AS (
    {{ get_latest_schedule_data(
        table_name = ref('dim_fare_leg_rules'),
    clean_table_name = 'dim_fare_leg_rules'
        ) }}
)

SELECT * FROM dim_fare_leg_rules_latest
