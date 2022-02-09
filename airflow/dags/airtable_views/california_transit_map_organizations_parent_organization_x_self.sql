---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_organizations_parent_organization_x_self

description: Self-join mapping table for the GTFS organizations table, parent_organization column in the California Transit Airtable base. Each row represents a relationship between two organizations records.

fields:
  organization_id: Internal Airtable ID for a organizations record
  parent_organization_id: Internal Airtable ID for a organizations record
  organization_name: organizations record name
  parent_organization_name: organizations record name

tests:
  check_null:
    - organization_id
    - parent_organization_id
    - organization_name
    - parent_organization_name
  check_composite_unique:
    - organization_id
    - parent_organization_id

external_dependencies:
  - airtable_loader: california_transit_organizations
---

-- follow the sandbox example for unnesting airtable data

WITH

unnested_t1 AS (
    SELECT
        T1.organization_id as organization_id
        , T1.name as organization_name
        , CAST(parent_organization AS STRING) AS parent_organization_id
    FROM
        `airtable.california_transit_organizations` T1
        , UNNEST(JSON_VALUE_ARRAY(parent_organization)) parent_organization
),
t2 AS (
    SELECT
        T2.organization_id as parent_organization_id
        , T2.name as parent_organization_name
    FROM
        `airtable.california_transit_organizations` T2
)

SELECT *
FROM unnested_t1
LEFT JOIN t2 USING(parent_organization_id)
