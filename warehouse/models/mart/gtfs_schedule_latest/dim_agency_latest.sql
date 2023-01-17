WITH
dim_agency_latest AS (
    {{ get_latest_schedule_data(
        table_name = ref('dim_agency'),
    clean_table_name = 'dim_agency'
        ) }}
)

SELECT * FROM dim_agency_latest
