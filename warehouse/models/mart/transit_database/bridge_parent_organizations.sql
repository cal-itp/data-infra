{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__organizations'),
        order_by = 'dt DESC'
        ) }}
),

unnest_parents AS (
    SELECT
        key AS organization_key,
        name AS organization_name,
        parent AS parent_organization_key,
        dt
    FROM latest,
        latest.parent_organization AS parent
),

bridge_parent_organizations AS (
    SELECT
        t1.* EXCEPT(dt),
        t2.name AS parent_organization_name,
        t1.dt
    FROM unnest_parents AS t1
    LEFT JOIN latest AS t2
        ON t1.parent_organization_key = t2.key
        AND t1.dt = t2.dt
)

SELECT * FROM bridge_parent_organizations
