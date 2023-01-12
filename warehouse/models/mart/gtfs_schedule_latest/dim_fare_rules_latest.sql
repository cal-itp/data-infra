WITH
dim_fare_rules_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_fare_rules')
    ) }}
)

SELECT * FROM dim_fare_rules_latest
