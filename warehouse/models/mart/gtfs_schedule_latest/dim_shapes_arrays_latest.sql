WITH
dim_shapes_arrays_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_shapes_arrays'),
    clean_table_name = 'dim_shapes_arrays'
    ) }}
)

SELECT * FROM dim_shapes_arrays_latest
