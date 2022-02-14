---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_organizations"

description: Data from the organizations table in the California Transit Airtable base. See Airtable data documentation for more information about its contents. This table represents only the most recent extract and does not track changes in data over time.

fields:
  organization_id: Internal Airtable ID for this organization record, used for joining with other Airtable views tables
  name: Organization name
  organization_type: Categorical data; example values "City/Town", "Joint Powers Agency"
  roles: Categorical choices imported as a string where a comma separates different selections; example values "Regional Transportation Planning Agency, Metropolitan Planning Organization"; "Metropolitan Planning Organization"
  itp_id: Cal-ITP ID
  details: Text description related to the organization

tests:
  check_null:
    - organization_id
    - name
  check_unique:
    - organization_id

dependencies:
  - dummy_airtable_loader
---
-- roles is a multi-select field in airtable
-- turn it into a string that's comma-delimited
  SELECT
    organization_id,
    name,
    organization_type,
    REPLACE(REPLACE(REPLACE(roles, "'",""), "[", ""), "]", "") roles,
    itp_id,
    details
  FROM `airtable.california_transit_organizations`
