{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'transit_technology_stacks__service_components'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

int_tts_services_ct_services_map AS (
    SELECT * FROM {{ ref('int_tts_services_ct_services_map') }}
),

mapped_service_ids AS (
    SELECT
        service_component_id,
        ARRAY_AGG(ct_key) AS services
    FROM latest, UNNEST(services) as tts_service_id
    LEFT JOIN int_tts_services_ct_services_map AS map
        ON tts_service_id = map.tts_key
        AND dt = map.tts_date
    GROUP BY service_component_id
),

stg_transit_database__service_components AS (
    SELECT
        service_component_id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        ntd_certified,
        product_component_valid,
        notes,
        T2.services,
        component,
        product,
        contracts,
    FROM latest
    LEFT JOIN mapped_service_ids AS T2
        USING(service_component_id)
)

SELECT * FROM stg_transit_database__service_components
