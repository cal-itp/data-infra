---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_place_geography"

tests:
  check_null:
    - place_geography_id
  check_unique:
    - place_geography_id

external_dependencies:
  - airtable_loader: california_transit_place_geography
---

  SELECT * FROM `airtable.california_transit_place_geography`
