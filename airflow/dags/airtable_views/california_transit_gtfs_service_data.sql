---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_gtfs_service_data"

description: Data from the gtfs service data table in the California Transit Airtable base. See Airtable data documentation for more information about its contents. This table represents only the most recent extract and does not track changes in data over time.

fields:
  service_id: Internal Airtable ID for this GTFS service data record, used for joining with other Airtable views tables
  name: Name for the GTFS dataset <> service relationship
  services: Internal Airtable ID for the service record in this relationship
  gtfs_dataset: Internal Airtable ID for the gtfs_dataset record in this relationship
  category: Indicates whether this is a primary, precursor, or unknown-type GTFS dataset/service relationship

tests:
  check_null:
    - gtfs_service_data_id
    - name
  check_unique:
    - gtfs_service_data_id

external_dependencies:
  - airtable_loader: california_transit_gtfs_service_data
---

  SELECT
    gtfs_service_data_id,
    name,
    -- service and gtfs_dataset are 1:1 foreign key fields
    -- but they export as an array from airtable
    -- turn them into a string for joining
    REPLACE(REPLACE(REPLACE(services, "'",""), "[", ""), "]", "") services,
    REPLACE(REPLACE(REPLACE(gtfs_dataset, "'",""), "[", ""), "]", "") gtfs_dataset,
    category
  FROM `airtable.california_transit_gtfs_service_data`
