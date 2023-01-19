WITH
dim_frequencies_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_frequencies'),
    clean_table_name = 'dim_frequencies'
    ) }}
)

SELECT * FROM dim_frequencies_latest
