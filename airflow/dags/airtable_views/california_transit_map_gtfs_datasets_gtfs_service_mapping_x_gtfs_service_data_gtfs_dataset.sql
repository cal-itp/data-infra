---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_gtfs_datasets_gtfs_service_mapping_x_gtfs_service_data_gtfs_dataset

description: Mapping table for the GTFS gtfs_datasets table, gtfs_service_mapping column and the gtfs_service_data table, gtfs_dataset column in the California Transit Airtable base. Each row represents a relationship between a gtfs_datasets record and a gtfs_service_data record.

fields:
  gtfs_dataset_id: Internal Airtable ID for a gtfs_datasets record
  gtfs_service_data_id: Internal Airtable ID for a gtfs_service_data record
  gtfs_dataset_name: gtfs_datasets record name
  gtfs_service_data_name: gtfs_service_data record name

tests:
  check_null:
    - gtfs_dataset_id
    - gtfs_service_data_id
    - gtfs_dataset_name
    - gtfs_service_data_name
  check_composite_unique:
    - gtfs_dataset_id
    - gtfs_service_data_id

external_dependencies:
  - airtable_loader: california_transit_gtfs_datasets
  - airtable_loader: california_transit_gtfs_service_data
---

-- follow the sandbox example for unnesting airtable data

WITH
unnested_t1 AS (
    SELECT
        T1.gtfs_dataset_id
        , T1.name as gtfs_dataset_name
        , CAST(gtfs_service_mapping AS STRING) AS gtfs_service_data_id
    FROM
        `airtable.california_transit_gtfs_datasets` T1
        , UNNEST(JSON_VALUE_ARRAY(gtfs_service_mapping)) gtfs_service_mapping
),
unnested_t2 AS (
    SELECT
        T2.gtfs_service_data_id
        , T2.name as gtfs_service_data_name
        , CAST(gtfs_dataset AS STRING) AS gtfs_dataset_id
    FROM
        `airtable.california_transit_gtfs_service_data` T2
        , UNNEST(JSON_VALUE_ARRAY(gtfs_dataset)) gtfs_dataset
)

SELECT *
FROM unnested_t1
FULL OUTER JOIN unnested_t2 USING(gtfs_dataset_id, gtfs_service_data_id)
