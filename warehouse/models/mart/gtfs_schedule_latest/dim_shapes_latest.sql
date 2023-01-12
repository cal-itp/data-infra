WITH
dim_shapes_latest AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'shapes',
    clean_table_name = ref('shapes_clean')
    ) }}
)

SELECT * FROM dim_shapes_latest
