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

dependencies:
  - dummy_airtable_loader
---

{{

  sql_airtable_mapping(
    table1 = "gtfs_datasets",table2 = "", col1 = "aggregated_to", col2 = ""
  )

}}
