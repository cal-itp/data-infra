

WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__properties_and_features'),
        order_by = 'time DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__properties_and_features AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        recommended_value,
        considerations,
        details,
        available_in_components,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__properties_and_features
