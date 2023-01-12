WITH
dim_shapes_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_shapes')
    ) }}
)

SELECT * FROM dim_shapes_latest
