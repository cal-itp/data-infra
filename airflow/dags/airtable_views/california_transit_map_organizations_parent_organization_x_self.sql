---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_organizations_parent_organization_x_self

description: Self-join mapping table for the GTFS organizations table, parent_organization column in the California Transit Airtable base. Each row represents a relationship between two organizations records.

fields:
  organization_id: Internal Airtable ID for a organizations record
  parent_organization_id: Internal Airtable ID for a organizations record
  organization_name: organizations record name
  parent_organization_name: organizations record name

tests:
  check_null:
    - organization_id
    - parent_organization_id
    - organization_name
    - parent_organization_name
  check_composite_unique:
    - organization_id
    - parent_organization_id

dependencies:
  - dummy_airtable_loader
---
{{

  sql_airtable_mapping(
    table1 = "organizations",table2 = "", col1 = "parent_organization", col2 = ""
  )

}}
