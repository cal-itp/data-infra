{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__services'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

unnest_paratransit AS (
    SELECT
        key AS service_key,
        name AS service_name,
        paratransit_for AS paratransit_for_service_key
    FROM latest,
        latest.paratransit_for AS paratransit_for
),

bridge_paratransit_services AS (
    SELECT
        t1.*,
        t2.name AS paratransit_for_service_name
    FROM unnest_paratransit AS t1
    LEFT JOIN latest AS t2
        ON t1.paratransit_for_service_key = t2.key
)

SELECT * FROM bridge_paratransit_services
