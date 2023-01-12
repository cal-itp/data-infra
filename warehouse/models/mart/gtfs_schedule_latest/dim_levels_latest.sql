WITH
dim_levels_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_levels')
    ) }}
)

SELECT * FROM dim_levels_latest
