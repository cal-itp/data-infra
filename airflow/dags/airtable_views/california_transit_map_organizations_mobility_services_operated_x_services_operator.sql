---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_organizations_mobility_services_operated_x_services_operator

description: Mapping table for the GTFS organizations table, mobility_services_operated column and the services table, operator column in the California Transit Airtable base. Each row represents a relationship between a organizations record and a services record.

fields:
  organization_id: Internal Airtable ID for a organizations record
  service_id: Internal Airtable ID for a services record
  organization_name: organizations record name
  service_name: services record name

tests:
  check_null:
    - organization_id
    - service_id
    - organization_name
    - service_name
  check_composite_unique:
    - organization_id
    - service_id

external_dependencies:
  - airtable_loader: california_transit_organizations
  - airtable_loader: california_transit_services
---
{{

  sql_airtable_mapping(
    table1 = "organizations", table2 = "services", col1 = "mobility_services_operated", col2 = "operator"
  )

}}
