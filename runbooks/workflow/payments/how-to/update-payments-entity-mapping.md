# Update Payments Entity Mapping

**Task:** Add or modify entity mapping for payments data\
**Time Required:** 15-30 minutes\
**Prerequisites:** GitHub write access, knowledge of agency identifiers

## Overview

Entity mapping links payments data from vendors (Littlepay, Enghouse, Elavon) to Cal-ITP's transit database entities (GTFS datasets and Organizations). This guide shows you how to add or update entity mappings.

## When to Update

Update entity mapping when:

- Onboarding a new agency
- Agency changes GTFS dataset
- Elavon customer name changes (rare)

## Finding source_record_ids

These allow an agency's payments data to be mapped to their GTFS and organization information. These values will be required in the steps below.

Unfortunately, these are somewhat manual processes. Use the queries below to filter the results down, and then manually page through the results until you find the `name` value of the agency that you are looking for. Once you've found the correct name, copy that `source_record_id` for that row.

**Note:** When in doubt, reach out to the customer success team for clarity around the expected Organization and GTFS Feed names for the agency.

```sql
-- Find GTFS dataset source_record_id
SELECT source_record_id, name
FROM `cal-itp-data-infra.mart_transit_database.dim_gtfs_datasets`
WHERE _is_current = TRUE
ORDER BY name ASC -- or DESC, depending on if the agency's name is towards the front or end of the alphabet

-- Find organization source_record_id
SELECT source_record_id, name
FROM `cal-itp-data-infra.mart_transit_database.dim_organizations`
WHERE _is_current = TRUE
ORDER BY name ASC -- or DESC, depending on if the agency's name is towards the front or end of the alphabet
```

Manually page through results to find the correct agency name, then copy the `source_record_id`.

## Littlepay Entity Mapping

### File Location

`warehouse/seeds/payments_entity_mapping.csv`

### Add New Entry

Add a new row:

```csv
<gtfs-dataset-source-record-id>,<organization-source-record-id>,<littlepay-participant-id>,<elavon-customer-name>,<_in_use_from>,<_in_use_until>
```

**Example:**

```csv
recysP9m9kjCJwHZe,receZJ9sEnP9vy3g0,mst,MST TAP TO RIDE,2000-01-01,2099-12-31
```

### Column Definitions

1. **gtfs_dataset_source_record_id** - The `source_record_id` from `dim_gtfs_datasets` for the agency's GTFS feed where `_is_current` is TRUE
2. **organization_source_record_id** - The `source_record_id` from `dim_organizations` for the agency where `_is_current` is TRUE
3. **littlepay_participant_id** - The `participant_id` from Littlepay
4. **elavon_customer_name** - Agency `customer_name` as it appears in Elavon data
5. **\_in_use_from** & **\_in_use_until**
   - These columns were added for the very rare circumstances when an agency's Elavon `customer_name` changes over time (as of this writing this only applies to sacrt)
   - For those agencies, align `_in_use_from` and `_in_use_until` dates to the `customer_name` cutover
   - For agencies where this doesn't apply, use arbitrary distant `_in_use_from` and `_in_use_until` dates such as `2000-01-01` and `2099-12-31`

## Enghouse Entity Mapping

### File Location

`warehouse/seeds/payments_entity_mapping_enghouse.csv`

### Add New Entry

Add a new row:

```csv
<gtfs-dataset-source-record-id>,<organization-source-record-id>,<enghouse-operator-id>,<elavon-customer-name>,<_in_use_from>,<_in_use_until>
```

**Example:**

```csv
recrAG7e0oOiR6FiP,rec7EN71rsZxDFxZd,253,Ventura County Transportation Commission,2000-01-01,2099-12-31
```

### Column Definitions

1. **gtfs_dataset_source_record_id** - The `source_record_id` from `dim_gtfs_datasets` where `_is_current` is TRUE
2. **organization_source_record_id** - The `source_record_id` from `dim_organizations` for the agency
3. **enghouse_operator_id** - Operator ID from Enghouse (no quotes around this value in the CSV)
4. **elavon_customer_name** - Agency name as it appears in Elavon data (if applicable)
5. **\_in_use_from** - Start date (typically `2000-01-01`)
6. **\_in_use_until** - End date (typically `2099-12-31`)

## Commit Changes

Create a pull request, get it reviewed, and merge.

## Verify

After dbt runs, verify the mapping:

```sql
-- For Littlepay
SELECT *
FROM `cal-itp-data-infra.staging.payments_entity_mapping`
WHERE littlepay_participant_id = '<participant-id>'

-- For Enghouse
SELECT *
FROM `cal-itp-data-infra.staging.payments_entity_mapping_enghouse`
WHERE enghouse_operator_id = '<operator-id>'
```

## Related Documentation

- [Onboard a New Littlepay Agency](onboard-littlepay-agency.md)
- [Onboard a New Enghouse Agency](onboard-enghouse-agency.md)
- [Update Row Access Policies](update-row-access-policies.md)
