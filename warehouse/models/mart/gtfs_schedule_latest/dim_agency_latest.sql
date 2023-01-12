WITH
dim_agency_latest AS (
    {{ get_latest_schedule_data(
        table_name = ref('dim_agency')
        ) }}
)

SELECT * FROM dim_agency_latest
