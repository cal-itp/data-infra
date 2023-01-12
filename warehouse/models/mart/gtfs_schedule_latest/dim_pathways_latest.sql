WITH
dim_pathways_latest AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'pathways',
    clean_table_name = ref('pathways_clean')
    ) }}
)

SELECT * FROM dim_pathways_latest
