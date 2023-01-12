WITH
dim_fare_rules_latest AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'fare_rules',
    clean_table_name = ref('fare_rules_clean')
    ) }}
)

SELECT * FROM dim_fare_rules_latest
