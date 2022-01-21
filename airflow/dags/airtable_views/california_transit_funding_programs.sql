---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_funding_programs"

tests:
  check_null:
    - funding_program_id
  check_unique:
    - funding_program_id

external_dependencies:
  - airtable_loader: california_transit_funding_programs
---

  SELECT * FROM `airtable.california_transit_funding_programs`
