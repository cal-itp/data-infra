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

dependencies:
  - dummy_airtable_loader
---
{{

  sql_airtable_mapping(
    table1 = "gtfs_datasets",table2 = "gtfs_service_data", col1 = "gtfs_service_mapping", col2 = "gtfs_dataset"
  )

}}
