---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_ntd_agency_info"

tests:
  check_null:
    - ntd_agency_info_id
  check_unique:
    - ntd_agency_info_id

external_dependencies:
  - airtable_loader: california_transit_ntd_agency_info
---

  SELECT * FROM `airtable.california_transit_ntd_agency_info`
