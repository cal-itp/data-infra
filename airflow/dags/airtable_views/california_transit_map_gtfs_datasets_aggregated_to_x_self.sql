---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_gtfs_datasets_aggregated_to_x_self

description: Self-join mapping table for the GTFS gtfs_datasets table, aggregated_to column in the California Transit Airtable base. Each row represents a relationship between two gtfs_datasets records.

fields:
  gtfs_dataset_id: Internal Airtable ID for a gtfs_datasets record
  aggregated_to_id: Internal Airtable ID for a gtfs_datasets record
  gtfs_dataset_name: gtfs_datasets record name
  aggregated_to_name: gtfs_datasets record name

tests:
  check_null:
    - gtfs_dataset_id
    - aggregated_to_id
    - gtfs_dataset_name
    - aggregated_to_name
  check_composite_unique:
    - gtfs_dataset_id
    - aggregated_to_id

external_dependencies:
  - airtable_loader: california_transit_gtfs_datasets
---

-- follow the sandbox example for unnesting airtable data

WITH

unnested_t1 AS (
    SELECT
        T1.gtfs_dataset_id as gtfs_dataset_id
        , T1.name as gtfs_dataset_name
        , CAST(aggregated_to AS STRING) AS aggregated_to_id
    FROM
        `airtable.california_transit_gtfs_datasets` T1
        , UNNEST(JSON_VALUE_ARRAY(aggregated_to)) aggregated_to
),
t2 AS (
    SELECT
        T2.gtfs_dataset_id as aggregated_to_id
        , T2.name as aggregated_to_name
    FROM
        `airtable.california_transit_gtfs_datasets` T2
)

SELECT *
FROM unnested_t1
LEFT JOIN t2 USING(aggregated_to_id)
