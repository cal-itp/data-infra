WITH
dim_levels_latest AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'levels',
    clean_table_name = ref('levels_clean')
    ) }}
)

SELECT * FROM dim_levels_latest
