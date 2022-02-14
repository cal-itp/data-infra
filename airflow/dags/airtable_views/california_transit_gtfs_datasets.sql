---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_gtfs_datasets"

description: Data from the GTFS datasets table in the California Transit Airtable base. See Airtable data documentation for more information about its contents. This table represents only the most recent extract and does not track changes in data over time.

fields:
  gtfs_dataset_id: Internal Airtable ID for this GTFS dataset record, used for joining with other Airtable views tables
  name: GTFS dataset name
  data: Single-select categorical choice imported as a string; example values "GTFS Alerts"; "GTFS Schedule"

tests:
  check_null:
    - gtfs_dataset_id
  check_unique:
    - gtfs_dataset_id

dependencies:
  - dummy_airtable_loader
---

SELECT
  gtfs_dataset_id,
  name,
  data,
FROM `airtable.california_transit_gtfs_datasets`
