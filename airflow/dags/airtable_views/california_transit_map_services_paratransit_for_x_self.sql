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
{{

  sql_airtable_mapping(
    table1 = "services",table2 = "", col1 = "paratransit_for", col2 = ""
  )

}}
