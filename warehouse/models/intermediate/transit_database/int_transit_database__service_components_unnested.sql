{{ config(materialized='ephemeral') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__service_components'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

stg_transit_database__service_components_unnested AS (
    SELECT
        key,
        service_key,
        product_key,
        component_key,
        ntd_certified,
        product_component_valid,
        notes,
        l.calitp_extracted_at
    FROM latest AS l
    LEFT JOIN UNNEST(l.services) AS service_key
    LEFT JOIN UNNEST(l.product) AS product_key
    LEFT JOIN UNNEST(l.component) AS component_key
    -- check that we have service and product actually defined
    WHERE (service_key IS NOT NULL) AND (product_key IS NOT NULL)
)

SELECT * FROM stg_transit_database__service_components_unnested
