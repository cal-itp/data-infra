{{ config(materialized='table') }}

WITH stg_transit_database__organizations AS (
    SELECT * FROM {{ ref('stg_transit_database__organizations') }}
),

unnest_parents AS (
    SELECT
        key AS organization_key,
        name AS organization_name,
        parent AS parent_organization_key
    FROM stg_transit_database__organizations,
        stg_transit_database__organizations.parent_organization AS parent
),

map_parent_organizations AS (
    SELECT
        t1.*,
        t2.name AS parent_organization_name
    FROM unnest_parents AS t1
    LEFT JOIN stg_transit_database__organizations AS t2
        ON t1.parent_organization_key = t2.key
)

SELECT * FROM map_parent_organizations
