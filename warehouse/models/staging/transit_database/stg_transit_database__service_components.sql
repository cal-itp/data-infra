WITH

latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__service_components'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

base_tts_services_ct_services_map AS (
    SELECT * FROM {{ ref('base_tts_services_ct_services_map') }}
),

mapped_service_ids AS (
    SELECT
        id,
        ARRAY_AGG(ct_key IGNORE NULLS) AS services,
        dt
    FROM latest
    LEFT JOIN UNNEST(latest.services) as tts_service_id
    LEFT JOIN base_tts_services_ct_services_map AS map
        ON tts_service_id = map.tts_key
        AND dt = map.tts_date
    GROUP BY id, dt
),

base_tts_service_components_idmap AS (
    SELECT
        T1.* EXCEPT(services),
        T2.services
    FROM latest AS T1
    LEFT JOIN mapped_service_ids AS T2
        USING(id, dt)
)


stg_transit_database__service_components AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        ntd_certified,
        product_component_valid,
        notes,
        services,
        component,
        product,
        dt AS calitp_extracted_at
    FROM base_tts_service_components_idmap
)

SELECT * FROM stg_transit_database__service_components
