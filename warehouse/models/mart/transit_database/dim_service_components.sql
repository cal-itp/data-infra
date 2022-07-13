{{ config(materialized='table') }}

WITH latest AS (
    SELECT *
    FROM {{ ref('int_transit_database__service_components_unnested') }}
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

ranked_service_components AS (
    SELECT
        key,
        service_key,
        product_key,
        component_key,
        ntd_certified,
        product_component_valid,
        notes,
        ROW_NUMBER() OVER
            (PARTITION BY service_key, product_key, component_key
            ORDER BY key) AS rank,
        calitp_extracted_at
    FROM latest
),

unique_service_components AS (
    SELECT
        * EXCEPT(rank)
    FROM ranked_service_components
    WHERE rank = 1
),

dim_service_components AS (
    SELECT
        {{ farm_surrogate_key(['service_key', 'product_key', 'COALESCE(component_key,"_")', 't1.calitp_extracted_at']) }} AS key,
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
    FROM unique_service_components AS t1
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
