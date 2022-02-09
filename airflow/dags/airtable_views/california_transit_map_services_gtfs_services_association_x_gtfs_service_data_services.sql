---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_services_gtfs_services_association_x_gtfs_service_data_services

description: Mapping table for the GTFS services table, gtfs_services_association column and the gtfs_service_data table, services column in the California Transit Airtable base. Each row represents a relationship between a services record and a gtfs_service_data record.

fields:
  service_id: Internal Airtable ID for a services record
  gtfs_service_data_id: Internal Airtable ID for a gtfs_service_data record
  service_name: services record name
  gtfs_service_data_name: gtfs_service_data record name

tests:
  check_null:
    - service_id
    - gtfs_service_data_id
    - service_name
    - gtfs_service_data_name
  check_composite_unique:
    - service_id
    - gtfs_service_data_id

external_dependencies:
  - airtable_loader: california_transit_services
  - airtable_loader: california_transit_gtfs_service_data
---

-- follow the sandbox example for unnesting airtable data

WITH
unnested_t1 AS (
    SELECT
        T1.service_id
        , T1.name as service_name
        , CAST(gtfs_services_association AS STRING) AS gtfs_service_data_id
    FROM
        `airtable.california_transit_services` T1
        , UNNEST(JSON_VALUE_ARRAY(gtfs_services_association)) gtfs_services_association
),
unnested_t2 AS (
    SELECT
        T2.gtfs_service_data_id
        , T2.name as gtfs_service_data_name
        , CAST(services AS STRING) AS service_id
    FROM
        `airtable.california_transit_gtfs_service_data` T2
        , UNNEST(JSON_VALUE_ARRAY(services)) services
)

SELECT *
FROM unnested_t1
FULL OUTER JOIN unnested_t2 USING(service_id, gtfs_service_data_id)
