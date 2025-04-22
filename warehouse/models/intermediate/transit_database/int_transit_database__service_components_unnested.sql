{{ config(materialized='ephemeral') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__service_components'),
        order_by = 'dt DESC'
        ) }}
),

int_transit_database__service_components_unnested AS (
    SELECT
        id,
        name,
        service_key,
        product_key,
        component_key,
        ntd_certified,
        product_component_valid,
        notes,
        start_date,
        end_date,
        is_active,
        l.dt,
        l.universal_first_val
    FROM latest AS l
    LEFT JOIN UNNEST(l.services) AS service_key
    LEFT JOIN UNNEST(l.product) AS product_key
    LEFT JOIN UNNEST(l.component) AS component_key
    -- check that we have service and product actually defined
    WHERE (service_key IS NOT NULL) AND (product_key IS NOT NULL)
)

SELECT * FROM int_transit_database__service_components_unnested
