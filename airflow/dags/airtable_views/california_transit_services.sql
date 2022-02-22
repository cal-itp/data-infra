---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_services"

description: Data from the services table in the California Transit Airtable base. See Airtable data documentation for more information about its contents. This table represents only the most recent extract and does not track changes in data over time.

fields:
  service_id: Internal Airtable ID for this service record, used for joining with other Airtable views tables
  name: Service name
  service_type: Categorical choices imported as a string where a comma separates different selections; example values "ADA paratransit, on-demand"; "fixed-route"
  mode: Categorical choices imported as a string where a comma separates different selections; example values "bus, car/van"; "ferry"
  currently_operating: Boolean for whether service is currently active

tests:
  check_null:
    - service_id
    - name
  check_unique:
    - service_id

dependencies:
  - dummy_airtable_loader
---

  SELECT
    service_id,
    name,
    -- service type and mode are multi-select fields in airtable
    -- turn them into a string that's comma-delimited
    REPLACE(REPLACE(REPLACE(service_type, "'",""), "[", ""), "]", "") service_type,
    REPLACE(REPLACE(REPLACE(mode, "'",""), "[", ""), "]", "") mode,
    currently_operating
  FROM `airtable.california_transit_services`
