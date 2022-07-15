

WITH
once_daily_service_components AS (
    SELECT *
    FROM {{ ref('base_tts_service_components_idmap') }}
),

stg_transit_database__service_components AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        ntd_certified,
        product_component_valid,
        notes,
        services,
        component,
        product,
        dt AS calitp_extracted_at
    FROM once_daily_service_components
)

SELECT * FROM stg_transit_database__service_components
