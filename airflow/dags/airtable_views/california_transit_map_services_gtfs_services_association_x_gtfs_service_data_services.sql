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
{{

  sql_airtable_mapping(
    table1 = "services",table2 = "gtfs_service_data", col1 = "gtfs_services_association", col2 = "services"
  )

}}
