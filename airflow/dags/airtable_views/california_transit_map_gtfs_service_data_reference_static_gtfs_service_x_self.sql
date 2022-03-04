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

dependencies:
  - dummy_airtable_loader
---
{{

  sql_airtable_mapping(
    table1 = "gtfs_service_data",table2 = "", col1 = "reference_static_gtfs_service", col2 = ""
  )

}}
