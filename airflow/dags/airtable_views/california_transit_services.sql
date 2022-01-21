---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_services"

tests:
  check_null:
    - service_id
  check_unique:
    - service_id

external_dependencies:
  - airtable_loader: california_transit_services
---

  SELECT * FROM `airtable.california_transit_services`
