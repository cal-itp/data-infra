WITH
dim_pathways_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_pathways'),
    clean_table_name = 'dim_pathways'
    ) }}
)

SELECT * FROM dim_pathways_latest
