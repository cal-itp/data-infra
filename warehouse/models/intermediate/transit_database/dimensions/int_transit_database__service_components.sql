{{ config(materialized='table') }}

WITH latest_service_components AS (
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

-- TODO: make this table actually historical
historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST(universal_first_val AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_service_components
),

-- join SCD tables: https://sqlsunday.com/2014/11/30/joining-two-scd2-tables/
dim_service_components AS (
    SELECT
        {{ dbt_utils.surrogate_key(['t1.id', 'GREATEST(t1._valid_from, t2._valid_from, t3._valid_from, t5._valid_from)']) }} AS key,
        t1.id AS original_record_id,
        t1.service_key,
        t2.name AS service_name,
        t1.product_key,
        t3.name AS product_name,
        t1.component_key,
        t5.name AS component_name,
        t1.ntd_certified,
        t1.product_component_valid,
        t1.notes,
        t1._is_current,
        GREATEST(t1._valid_from, t2._valid_from, t3._valid_from, t5._valid_from) AS _valid_from,
        LEAST(t1._valid_to, t2._valid_to, t3._valid_to, t5._valid_to) AS _valid_to
    FROM historical AS t1
    LEFT JOIN dim_services AS t2
        ON t1.service_key = t2.key
        AND t1._valid_from < t2._valid_to
        AND t1._valid_to > t2._valid_from
    LEFT JOIN dim_products AS t3
        ON t1.product_key = t3.key
        AND t1._valid_from < t3._valid_to
        AND t1._valid_to > t3._valid_from
    LEFT JOIN dim_components AS t5
        ON t1.component_key = t5.key
        AND t1._valid_from < t5._valid_to
        AND t1._valid_to > t5._valid_from
)

SELECT * FROM dim_service_components
