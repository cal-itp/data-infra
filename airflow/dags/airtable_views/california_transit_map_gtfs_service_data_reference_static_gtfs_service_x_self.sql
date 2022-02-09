---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_gtfs_service_data_reference_static_gtfs_service_x_self

description: Self-join mapping table for the GTFS gtfs_service_data table, reference_static_gtfs_service column in the California Transit Airtable base. Each row represents a relationship between two gtfs_service_data records.

fields:
  gtfs_service_data_id: Internal Airtable ID for a gtfs_service_data record
  reference_static_gtfs_service_id: Internal Airtable ID for a gtfs_service_data record
  gtfs_service_data_name: gtfs_service_data record name
  reference_static_gtfs_service_name: gtfs_service_data record name

tests:
  check_null:
    - gtfs_service_data_id
    - reference_static_gtfs_service_id
    - gtfs_service_data_name
    - reference_static_gtfs_service_name
  check_composite_unique:
    - gtfs_service_data_id
    - reference_static_gtfs_service_id

external_dependencies:
  - airtable_loader: california_transit_gtfs_service_data
---

-- follow the sandbox example for unnesting airtable data

WITH

unnested_t1 AS (
    SELECT
        T1.gtfs_service_data_id as gtfs_service_data_id
        , T1.name as gtfs_service_data_name
        , CAST(reference_static_gtfs_service AS STRING) AS reference_static_gtfs_service_id
    FROM
        `airtable.california_transit_gtfs_service_data` T1
        , UNNEST(JSON_VALUE_ARRAY(reference_static_gtfs_service)) reference_static_gtfs_service
),
t2 AS (
    SELECT
        T2.gtfs_service_data_id as reference_static_gtfs_service_id
        , T2.name as reference_static_gtfs_service_name
    FROM
        `airtable.california_transit_gtfs_service_data` T2
)

SELECT *
FROM unnested_t1
LEFT JOIN t2 USING(reference_static_gtfs_service_id)
