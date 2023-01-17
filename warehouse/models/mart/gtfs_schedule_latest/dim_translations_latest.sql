WITH
dim_translations_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_translations'),
    clean_table_name = 'dim_translations'
    ) }}
)

SELECT * FROM dim_translations_latest
