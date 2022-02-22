---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_gtfs_datasets_dataset_publisher_x_organizations_gtfs_datasets

description: Mapping table for the GTFS gtfs_datasets table, dataset_publisher column and the organizations table, gtfs_datasets column in the California Transit Airtable base. Each row represents a relationship between a gtfs_datasets record and a organizations record.

fields:
  gtfs_dataset_id: Internal Airtable ID for a gtfs_datasets record
  organization_id: Internal Airtable ID for a organizations record
  gtfs_dataset_name: gtfs_datasets record name
  organization_name: organizations record name

tests:
  check_null:
    - gtfs_dataset_id
    - organization_id
    - gtfs_dataset_name
    - organization_name
  check_composite_unique:
    - gtfs_dataset_id
    - organization_id

dependencies:
  - dummy_airtable_loader
---
{{

  sql_airtable_mapping(
    table1 = "gtfs_datasets",table2 = "organizations", col1 = "dataset_publisher", col2 = "gtfs_datasets"
  )

}}
