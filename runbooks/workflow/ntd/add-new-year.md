# Add a New Year's Data to the NTD Pipeline

**Task:** Onboard a new NTD reporting year into the data pipeline\
**Time Required:** 30–60 minutes\
**Prerequisites:** GitHub write access, Airflow access

## Overview

The NTD (National Transit Database) pipeline ingests annual reporting data from the FTA website. Each new reporting year requires changes in six places: the Airflow download DAG, the external table definitions, the dbt source definitions, the dbt staging models, the intermediate union models, and the year constraint in dbt tests. The historical time-series tables (ridership, assets, expenses, etc.) update automatically and do not require year-specific changes.

## Before You Start

- [ ] Confirm the new year's XLSX files are published on the FTA NTD website. The two year-specific products are:
  - `https://www.transit.dot.gov/ntd/data-product/YYYY-annual-database-agency-information`
  - `https://www.transit.dot.gov/ntd/data-product/YYYY-annual-database-contractual-relationship`
  - If either URL 404s, the data is not yet published. Check back when it is.

## Step 1: Update the Airflow Download DAG

File: `airflow/dags/download_and_parse_ntd_xlsx.py`

Add two new entries to the `NTD_PRODUCTS` list — one for each year-specific product type. Follow the existing pattern:

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

Create two new YAML files by copying the previous year's files and updating all year references:

```bash
cp 2024__annual_database_agency_information.yml YYYY__annual_database_agency_information.yml
cp 2024__annual_database_contractual_relationships.yml YYYY__annual_database_contractual_relationships.yml
```

In each new file, replace all occurrences of `2024` with `YYYY`. There are four places in each file:

- The `post_hook` SELECT statement table name
- The `source_objects` path
- The `destination_project_dataset_table` value
- The `hive_options.source_uri_prefix` path

## Step 3: Update dbt Source Definitions

File: `warehouse/models/staging/ntd_annual_reporting/_src.yml`

Add source table entries for the new year. For `agency_information`, copy the full `2024__annual_database_agency_information` block (with all column definitions) and update the name and description year. For `contractual_relationships`, add a single name entry alongside the others:

```yaml
- name: YYYY__annual_database_agency_information
  description: |
    Contains YYYY basic contact and agency information for each NTD reporter.
  columns:
    # (copy column list from 2024 entry)
```

```yaml
- name: YYYY__annual_database_contractual_relationships
```

## Step 4: Create Staging Model SQL Files

Directory: `warehouse/models/staging/ntd_annual_reporting/`

Create two new SQL files by copying the previous year's files:

```bash
cp stg_ntd__2024_agency_information.sql stg_ntd__YYYY_agency_information.sql
cp stg_ntd__2024_contractual_relationships.sql stg_ntd__YYYY_contractual_relationships.sql
```

In each file, replace all occurrences of `2024` with `YYYY`. This updates the source reference and the final CTE name.

## Step 5: Update Intermediate Union Models

These two models manually `UNION ALL` the year-specific staging models and must be extended for each new year.

**5a.** File: `warehouse/models/intermediate/ntd_annual_reporting/int_ntd__unioned_agency_information.sql`

Add a new CTE at the top of the file and a new `UNION ALL` block at the bottom, following the 2024 pattern. Note: some columns are set to `NULL` for specific years where the NTD source did not include them (e.g., `division_department` is `NULL AS division_department` for 2022 and 2024 but present in 2023). Before copying the 2024 block, verify whether each nullable column exists in the new year's staging model. If it does not, keep `NULL AS column_name`.

**5b.** File: `warehouse/models/intermediate/ntd_annual_reporting/int_ntd__unioned_contractual_relationships.sql`

Add a new CTE and `UNION ALL` block following the 2024 pattern. Columns are consistent across years for this model, so copying the 2024 block directly should be safe — but verify against the new year's staging model if any test failures occur.

## Step 6: Update Year Constraints in dbt

**6a.** File: `warehouse/models/staging/ntd_annual_reporting/_stg_ntd_annual_reporting.yml`

Update the `report_year` accepted values constraint (line ~28) and add model documentation entries for both new staging models. Copy the `stg_ntd__2024_agency_information` block and update the year in the name and description:

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
    # (copy column list from 2024 entry)

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
| `warehouse/models/mart/ntd/_mart_ntd.yml`                                                                   | Update ~5 year constraints                  |
| `warehouse/models/intermediate/ntd_annual_reporting/int_ntd__unioned_agency_information.sql`                | Add CTE + UNION ALL block                   |
| `warehouse/models/intermediate/ntd_annual_reporting/int_ntd__unioned_contractual_relationships.sql`         | Add CTE + UNION ALL block                   |
