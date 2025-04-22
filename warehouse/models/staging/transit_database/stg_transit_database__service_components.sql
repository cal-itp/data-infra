WITH

once_daily_service_components AS (
    SELECT *
    FROM {{ ref('base_tts_service_components_idmap') }}
),

stg_transit_database__service_components AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        ntd_certified,
        product_component_valid,
        notes,
        services,
        component,
        product,
        start_date,
        end_date,
        is_active,
        dt
    FROM once_daily_service_components
)

SELECT * FROM stg_transit_database__service_components
