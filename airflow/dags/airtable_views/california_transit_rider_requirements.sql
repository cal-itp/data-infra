---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_rider_requirements"

tests:
  check_null:
    - rider_requirement_id
  check_unique:
    - rider_requirement_id

external_dependencies:
  - airtable_loader: california_transit_rider_requirements
---

  SELECT * FROM `airtable.california_transit_rider_requirements`
