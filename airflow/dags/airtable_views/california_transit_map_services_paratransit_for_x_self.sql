---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_services_paratransit_for_x_self

description: Self-join mapping table for the GTFS services table, paratransit_for column in the California Transit Airtable base. Each row represents a relationship between two services records.

fields:
  service_id: Internal Airtable ID for a services record
  paratransit_for_id: Internal Airtable ID for a services record
  service_name: services record name
  paratransit_for_name: services record name

tests:
  check_null:
    - service_id
    - paratransit_for_id
    - service_name
    - paratransit_for_name
  check_composite_unique:
    - service_id
    - paratransit_for_id

external_dependencies:
  - airtable_loader: california_transit_services
---

-- follow the sandbox example for unnesting airtable data

WITH

unnested_t1 AS (
    SELECT
        T1.service_id as service_id
        , T1.name as service_name
        , CAST(paratransit_for AS STRING) AS paratransit_for_id
    FROM
        `airtable.california_transit_services` T1
        , UNNEST(JSON_VALUE_ARRAY(paratransit_for)) paratransit_for
),
t2 AS (
    SELECT
        T2.service_id as paratransit_for_id
        , T2.name as paratransit_for_name
    FROM
        `airtable.california_transit_services` T2
)

SELECT *
FROM unnested_t1
LEFT JOIN t2 USING(paratransit_for_id)
