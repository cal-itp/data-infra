WITH

once_daily_data_schemas AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__data_schemas'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__data_schemas AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        status,
        products AS input_products,
        products_copy AS output_products,
        dt
    FROM once_daily_data_schemas
)

SELECT * FROM stg_transit_database__data_schemas
