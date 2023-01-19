WITH

once_daily_properties_and_features AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__properties_and_features'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__properties_and_features AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        recommended_value,
        considerations,
        details,
        available_in_components,
        dt
    FROM once_daily_properties_and_features
)

SELECT * FROM stg_transit_database__properties_and_features
