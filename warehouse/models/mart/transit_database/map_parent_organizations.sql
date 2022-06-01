{{ config(materialized='table') }}

WITH stg_transit_database__organizations AS (
    SELECT * FROM {{ ref('stg_transit_database__organizations') }}
),

unnest_parents AS (
    SELECT
        id AS organization_id,
        name AS organization_name,
        parent AS parent_organization_id
    FROM stg_transit_database__organizations,
        stg_transit_database__organizations.parent_organization AS parent
),

map_parent_organizations AS (
    SELECT
        t1.*,
        t2.name AS parent_organization_name
    FROM unnest_parents AS t1
    LEFT JOIN stg_transit_database__organizations AS t2
        ON t1.parent_organization_id = t2.id
)

SELECT * FROM map_parent_organizations
