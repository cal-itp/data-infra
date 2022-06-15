{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__properties_and_features'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__properties_and_features AS (
    SELECT
        property_feature_id AS key,
        name,
        recommended_value,
        considerations,
        details,
        available_in_components,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__properties_and_features
