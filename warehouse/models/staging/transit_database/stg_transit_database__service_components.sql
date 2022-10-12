WITH

source AS (
    SELECT * FROM {{ source('airtable_tts', 'transit_technology_stacks__service_components') }}
),

base_tts_services_ct_services_map AS (
    SELECT * FROM {{ ref('base_tts_services_ct_services_map') }}
),

mapped_service_ids AS (
    SELECT
        id,
        ARRAY_AGG(map.ct_key IGNORE NULLS) AS services,
        ts
    FROM source
    LEFT JOIN UNNEST(source.services) as tts_service_id
    LEFT JOIN base_tts_services_ct_services_map AS map
        ON tts_service_id = map.tts_key
        AND source.ts between map._valid_from and map._valid_to
    GROUP BY id, ts
),

stg_transit_database__service_components AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        ntd_certified,
        product_component_valid,
        notes,
        mapped_service_ids.services,
        component,
        product,
        ts
    FROM source
    LEFT JOIN mapped_service_ids
        USING (id, ts)
)

SELECT * FROM stg_transit_database__service_components
