---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_county_geography"

tests:
  check_null:
    - county_geography_id
  check_unique:
    - county_geography_id

external_dependencies:
  - airtable_loader: california_transit_county_geography
---

  SELECT * FROM `airtable.california_transit_county_geography`
