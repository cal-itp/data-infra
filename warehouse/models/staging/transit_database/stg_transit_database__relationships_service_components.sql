WITH

once_daily_relationships_service_components AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__relationships_service_components'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__relationships_service_components AS (
    SELECT * EXCEPT(name),
    {{ trim_make_empty_string_null(column_name = "name") }} AS name
    FROM once_daily_relationships_service_components
)

SELECT * FROM stg_transit_database__relationships_service_components
