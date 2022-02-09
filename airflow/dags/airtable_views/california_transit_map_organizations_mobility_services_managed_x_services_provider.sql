---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_organizations_mobility_services_managed_x_services_provider

description: Mapping table for the GTFS organizations table, mobility_services_managed column and the services table, provider column in the California Transit Airtable base. Each row represents a relationship between a organizations record and a services record.

fields:
  organization_id: Internal Airtable ID for a organizations record
  service_id: Internal Airtable ID for a services record
  organization_name: organizations record name
  service_name: services record name

tests:
  check_null:
    - organization_id
    - service_id
    - organization_name
    - service_name
  check_composite_unique:
    - organization_id
    - service_id

external_dependencies:
  - airtable_loader: california_transit_organizations
  - airtable_loader: california_transit_services
---

-- follow the sandbox example for unnesting airtable data

WITH
unnested_t1 AS (
    SELECT
        T1.organization_id
        , T1.name as organization_name
        , CAST(mobility_services_managed AS STRING) AS service_id
    FROM
        `airtable.california_transit_organizations` T1
        , UNNEST(JSON_VALUE_ARRAY(mobility_services_managed)) mobility_services_managed
),
unnested_t2 AS (
    SELECT
        T2.service_id
        , T2.name as service_name
        , CAST(provider AS STRING) AS organization_id
    FROM
        `airtable.california_transit_services` T2
        , UNNEST(JSON_VALUE_ARRAY(provider)) provider
)

SELECT *
FROM unnested_t1
FULL OUTER JOIN unnested_t2 USING(organization_id, service_id)
