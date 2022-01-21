---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_eligibility_programs"

tests:
  check_null:
    - eligibility_program_id
  check_unique:
    - eligibility_program_id

external_dependencies:
  - airtable_loader: california_transit_eligibility_programs
---

  SELECT * FROM `airtable.california_transit_eligibility_programs`
