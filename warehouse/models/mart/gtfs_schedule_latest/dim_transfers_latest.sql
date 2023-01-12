WITH
dim_transfers_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_transfers')
    ) }}
)

SELECT * FROM dim_transfers_latest
