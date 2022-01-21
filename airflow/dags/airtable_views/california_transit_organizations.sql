---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_organizations"

tests:
  check_null:
    - organization_id
  check_unique:
    - organization_id

external_dependencies:
  - airtable_loader: california_transit_organizations
---

  SELECT * FROM `airtable.california_transit_organizations`
