WITH
dim_agency_latest AS (
    {{ get_latest_schedule_data(
        latest_only_source = ref('calitp_feeds'),
        table_name = 'agency',
        clean_table_name = ref('agency_clean')
        ) }}
)

SELECT * FROM dim_agency_latest
