---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_service_component"

tests:
  check_null:
    - service_component_id
  check_unique:
    - service_component_id

external_dependencies:
  - airtable_loader: california_transit_service_component
---

  SELECT * FROM `airtable.california_transit_service_component`
