# Add a New Year's Data to the NTD Pipeline

**Task:** Onboard a new NTD reporting year into the data pipeline\
**Time Required:** 30–60 minutes\
**Prerequisites:** GitHub write access, Airflow access

> **Note on `YYYY`:** Throughout this document, `YYYY` refers to the four-digit reporting year being added (e.g., `2025`). Replace it with the actual year everywhere it appears.

## Overview

The NTD pipeline has two distinct data sources that behave differently when a new year is published:

- **XLSX annual reporting tables** (`agency_information`, `contractual_relationships`) — These are published as year-specific XLSX files on the FTA website and require manual onboarding steps each year (Steps 1–6 below).
- **API-synced multi-year tables** (breakdowns, service, funding, expenses, etc.) — These are pulled from SODA API endpoints that return data for all years at once. When NTD publishes a new year, those endpoints automatically include it on the next scheduled DAG run. No new configs are needed for these tables. The only required change is updating the dbt year constraints in Step 6, which applies to both data sources.

## Before You Start

- [ ] Confirm the new year's XLSX files are published on the FTA NTD website. Based on prior years, the URLs have followed this pattern — but NTD has changed URL structures before, so verify rather than assume:
  - `https://www.transit.dot.gov/ntd/data-product/YYYY-annual-database-agency-information`
  - `https://www.transit.dot.gov/ntd/data-product/YYYY-annual-database-contractual-relationship`
  - If the URLs have changed, find the correct ones from the [NTD data products page](https://www.transit.dot.gov/ntd/ntd-data) before proceeding.

## Step 1: Update the Airflow Download DAG

File: `airflow/dags/download_and_parse_ntd_xlsx.py`

Add two new entries to the `NTD_PRODUCTS` list — one for each year-specific product type. Follow the existing pattern, using the confirmed URLs from the step above:

```python
{
    "type": "annual_database_agency_information",
    "url": "/ntd/data-product/YYYY-annual-database-agency-information",
    "year": "YYYY",
},
{
    "type": "annual_database_contractual_relationship",
    "url": "/ntd/data-product/YYYY-annual-database-contractual-relationship",
    "year": "YYYY",
},
```

Place them alongside the existing entries for the same product types (not at the end of the list).

## Step 2: Create External Table YAML Definitions

Directory: `airflow/dags/create_external_tables/ntd_data_products/`

Create two new YAML files by duplicating the most recent year's files and renaming them for the new year (e.g., `2025__annual_database_agency_information.yml`). In each new file, replace all occurrences of the prior year with `YYYY`. There are four places in each file:

- The `post_hook` SELECT statement table name
- The `source_objects` path
- The `destination_project_dataset_table` value
- The `hive_options.source_uri_prefix` path

## Step 3: Update dbt Source Definitions

File: `warehouse/models/staging/ntd_annual_reporting/_src.yml`

Add source table entries for the new year. For `agency_information`, copy the full prior year block (with all column definitions) and update the name and description year. For `contractual_relationships`, add a single name entry alongside the others:

```yaml
- name: YYYY__annual_database_agency_information
  description: |
    Contains YYYY basic contact and agency information for each NTD reporter.
  columns:
    # (copy column list from prior year entry)
```

```yaml
- name: YYYY__annual_database_contractual_relationships
```

## Step 4: Create Staging Model SQL Files

Directory: `warehouse/models/staging/ntd_annual_reporting/`

Create two new SQL files by duplicating the most recent year's files and renaming them for the new year (e.g., `stg_ntd__2025_agency_information.sql`). In each file, replace all occurrences of the prior year with `YYYY`. This updates the source reference and the final CTE name.

## Step 5: Update Intermediate Union Models

These two models manually `UNION ALL` the year-specific staging models and must be extended for each new year.

**5a.** File: `warehouse/models/intermediate/ntd_annual_reporting/int_ntd__unioned_agency_information.sql`

Add a new CTE at the top of the file and a new `UNION ALL` block at the bottom, following the prior year's pattern. NTD has historically changed its schema between reporting years — some columns have been added, removed, or renamed. Before copying the prior year's block, verify each column exists in the new year's staging model. For any column present in prior years but absent in the new year, use `NULL AS column_name`. For any new column not present in prior years, add it to all existing `UNION ALL` blocks as `NULL AS column_name` to keep the schema consistent.

**5b.** File: `warehouse/models/intermediate/ntd_annual_reporting/int_ntd__unioned_contractual_relationships.sql`

Add a new CTE and `UNION ALL` block following the prior year's pattern. Apply the same schema verification as 5a — do not assume columns are consistent across years.

## Step 6: Update Year Constraints in dbt

This step is required for both the XLSX annual tables and the API-synced multi-year tables. The `report_year` constraint is shared across both via a YAML anchor.

**6a.** File: `warehouse/models/staging/ntd_annual_reporting/_stg_ntd_annual_reporting.yml`

Update the `report_year` accepted values constraint (line ~28) and add model documentation entries for both new staging models. Copy the prior year's `stg_ntd__YYYY_agency_information` block and update the year in the name and description:

```yaml
- accepted_values:
    arguments:
      values: [2022, 2023, 2024, YYYY]
```

```yaml
- name: stg_ntd__YYYY_agency_information
  description: |
    Contains YYYY basic contact and agency information for each NTD reporter.
  columns:
    # (copy column list from prior year entry)

- name: stg_ntd__YYYY_contractual_relationships
```

**6b.** File: `warehouse/models/mart/ntd/_mart_ntd.yml`

This file has **four** `accepted_values` constraints for `report_year`. Search for `values: [2022, 2023, 2024]` and update all occurrences.

## Step 7: Deploy and Trigger Airflow

After merging the PR:

1. **Trigger `download_and_parse_ntd_xlsx`** manually in Airflow. This downloads the new year's XLSX from the FTA website, converts it to JSONL, and writes it to the clean GCS bucket. The DAG normally runs weekly on Mondays so a manual trigger ensures it runs promptly.

2. **Trigger `create_external_tables`** after the download DAG completes. This registers the new year's external tables in BigQuery.

## Step 8: Build and Test in dbt

```bash
uv run dbt run -s stg_ntd__YYYY_agency_information stg_ntd__YYYY_contractual_relationships int_ntd__unioned_agency_information int_ntd__unioned_contractual_relationships --vars 'GOOGLE_CLOUD_PROJECT: cal-itp-data-infra'
uv run dbt test -s stg_ntd__YYYY_agency_information stg_ntd__YYYY_contractual_relationships --vars 'GOOGLE_CLOUD_PROJECT: cal-itp-data-infra'
```

Verify the new staging models return rows and the `report_year` test passes.

## Summary of Files Changed

| File                                                                                                        | Change                                      |
| ----------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| `airflow/dags/download_and_parse_ntd_xlsx.py`                                                               | Add 2 entries to `NTD_PRODUCTS`             |
| `airflow/dags/create_external_tables/ntd_data_products/YYYY__annual_database_agency_information.yml`        | New file (copy + update from prior year)    |
| `airflow/dags/create_external_tables/ntd_data_products/YYYY__annual_database_contractual_relationships.yml` | New file (copy + update from prior year)    |
| `warehouse/models/staging/ntd_annual_reporting/_src.yml`                                                    | Add 2 source entries                        |
| `warehouse/models/staging/ntd_annual_reporting/stg_ntd__YYYY_agency_information.sql`                        | New file (copy + update from prior year)    |
| `warehouse/models/staging/ntd_annual_reporting/stg_ntd__YYYY_contractual_relationships.sql`                 | New file (copy + update from prior year)    |
| `warehouse/models/staging/ntd_annual_reporting/_stg_ntd_annual_reporting.yml`                               | Update year constraint, add 2 model entries |
| `warehouse/models/mart/ntd/_mart_ntd.yml`                                                                   | Update 4 year constraints                   |
| `warehouse/models/intermediate/ntd_annual_reporting/int_ntd__unioned_agency_information.sql`                | Add CTE + UNION ALL block                   |
| `warehouse/models/intermediate/ntd_annual_reporting/int_ntd__unioned_contractual_relationships.sql`         | Add CTE + UNION ALL block                   |
