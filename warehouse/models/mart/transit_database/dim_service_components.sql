{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__service_components'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_components AS (
    SELECT * FROM {{ ref('dim_components') }}
),

dim_services AS (
    SELECT * FROM {{ ref('dim_services') }}
),

dim_products AS (
    SELECT * FROM {{ ref('dim_products') }}
),

unnest_service_components AS (
    SELECT
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
),

dim_service_components AS (
    SELECT
        {{ farm_surrogate_key(['COALESCE(service_key,"_")', 'COALESCE(product_key,"_")', 'COALESCE(component_key,"_")', 't1.calitp_extracted_at']) }} AS key,
        t1.service_key,
        t2.name AS service_name,
        t1.product_key,
        t3.name AS product_name,
        t1.component_key,
        t5.name AS component_name,
        t1.ntd_certified,
        t1.product_component_valid,
        t1.notes,
        t1.calitp_extracted_at
    FROM unnest_service_components AS t1
    LEFT JOIN dim_services AS t2
        ON t1.service_key = t2.key
        AND t1.calitp_extracted_at = t2.calitp_extracted_at
    LEFT JOIN dim_products AS t3
        ON t1.product_key = t3.key
        AND t1.calitp_extracted_at = t2.calitp_extracted_at
    LEFT JOIN dim_components AS t5
        ON t1.component_key = t5.key
        AND t1.calitp_extracted_at = t2.calitp_extracted_at
)

SELECT * FROM dim_service_components
