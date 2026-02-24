# Onboard a New Enghouse Agency

**Task:** Set up data pipeline for a new agency using Enghouse for fare collection\
**Time Required:** 1-2 hours\
**Prerequisites:** GCP access, GitHub write access, Terraform permissions

## Overview

This guide walks you through onboarding a new transit agency that uses Enghouse for contactless fare collection. Enghouse is an alternative fare collection provider to Littlepay, used by some Cal-ITP partner agencies.

## Before You Start

### Information Needed

Collect the following before starting:

- [ ] Enghouse data access credentials/method
- [ ] Enghouse operator ID for the agency
- [ ] Agency's GTFS dataset identifier in Cal-ITP system
- [ ] Agency contact information for dashboard access
- [ ] Elavon organization name (if applicable)

### Required Access

Verify you have:

- [ ] GCP project `cal-itp-data-infra` access
- [ ] Secret Manager admin permissions (if credentials needed)
- [ ] GitHub write access to `cal-itp/data-infra`
- [ ] Terraform apply permissions (for service account creation)
- [ ] Access to Enghouse data delivery method

### Understanding Enghouse Data

**Key Differences from Littlepay:**

- Enghouse provides data via different delivery mechanism (check current implementation)
- Uses `operator_id` instead of `participant_id`/`merchant_id`
- Different data schema and table structure
- Separate entity mapping file (`payments_entity_mapping_enghouse.csv`)

**Enghouse Tables:**

- `taps` - Tap events from validators
- `transactions` - Transaction records
- `ticket_results` - Ticket/fare validation results
- `pay_windows` - Payment window configurations

## Step 1: Understand Data Access Method

**Enghouse Data Delivery:**

Enghouse delivers data daily via SFTP server directly to our GCS bucket. This differs from Littlepay's S3-based approach.

**Implementation Details:**

- Data is delivered directly to `gs://calitp-enghouse-raw/` via SFTP
- No sync DAG is needed (data arrives directly in GCS)
- External tables read from `gs://calitp-enghouse-raw/`
- Data refresh: Daily

**For New Agency Onboarding:**

1. Coordinate with Enghouse to set up SFTP delivery for the new agency
2. Verify data appears in `gs://calitp-enghouse-raw/` after delivery is configured
3. Confirm the agency's `operator_id` in the delivered data

## Step 2: Create Service Account

The agency needs a dedicated service account for accessing their payments data with row-level security.

### 2.1 Create Service Account via Terraform

Create a new branch:

```bash
cd /path/to/data-infra
git checkout main
git pull
git checkout -b onboard-<agency-name>-payments
```

**Edit `iac/cal-itp-data-infra/iam/us/service_account.tf`:**

Add a new service account resource:

```hcl
resource "google_service_account" "<agency>_payments_user" {
  account_id   = "<agency-slug>-payments-user"
  display_name = "<Agency Name> Payments User"
  description  = "Service account for <Agency Name> payments data access"
  project      = var.project_id
}
```

**Edit `iac/cal-itp-data-infra/iam/us/project_iam_member.tf`:**

Add BigQuery user role binding:

```hcl
resource "google_project_iam_member" "<agency>_payments_user_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.<agency>_payments_user.email}"
}
```

### 2.2 Commit and Create PR

```bash
git add iac/cal-itp-data-infra/iam/us/service_account.tf
git add iac/cal-itp-data-infra/iam/us/project_iam_member.tf
git commit -m "Add <Agency Name> payments service account"
git push origin onboard-<agency-name>-payments
```

Create a pull request, get it reviewed, and merge.

**Example PR:** <!-- TODO: Add link to example PR for Enghouse service account creation -->

### 2.3 Download Service Account Key

After the PR is merged and Terraform runs:

```bash
gcloud iam service-accounts keys create <agency-slug>-payments-key.json \
  --iam-account=<agency-slug>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com \
  --project=cal-itp-data-infra
```

Store this file securely for Metabase configuration.

## Step 3: Add Entity Mapping

Enghouse agencies use a separate entity mapping file.

### 3.1 Edit Entity Mapping

Edit `warehouse/seeds/payments_entity_mapping_enghouse.csv`:

Add a new row:

```csv
<gtfs-dataset-source-record-id>,<organization-source-record-id>,<enghouse-operator-id>,<elavon-customer-name>,<_in_use_from>,<_in_use_until>
```

**Example (from actual file):**

```csv
recrAG7e0oOiR6FiP,rec7EN71rsZxDFxZd,253,Ventura County Transportation Commission,2000-01-01,2099-12-31
```

**Column Definitions:**

1. **gtfs_dataset_source_record_id** - The `source_record_id` from `dim_gtfs_datasets` where `_is_current` is TRUE
2. **organization_source_record_id** - The `source_record_id` from `dim_organizations` for the agency
3. **enghouse_operator_id** - Operator ID from Enghouse (numeric, no quotes in CSV)
4. **elavon_customer_name** - Agency name as it appears in Elavon data (if applicable)
5. **\_in_use_from** - Start date (typically `2000-01-01`)
6. **\_in_use_until** - End date (typically `2099-12-31`)

**To find the source_record_ids:**

```sql
-- Find GTFS dataset source_record_id
SELECT source_record_id, name
FROM `cal-itp-data-infra.mart_transit_database.dim_gtfs_datasets`
WHERE name LIKE '%<Agency Name>%'
  AND _is_current = TRUE

-- Find organization source_record_id
SELECT source_record_id, name
FROM `cal-itp-data-infra.mart_transit_database.dim_organizations`
WHERE name LIKE '%<Agency Name>%'
```

### 3.2 Commit Entity Mapping

```bash
git add warehouse/seeds/payments_entity_mapping_enghouse.csv
git commit -m "Add <Agency Name> to Enghouse entity mapping"
git push origin onboard-<agency-name>-payments
```

Update your PR or create a new one.

**Example PR:** <!-- TODO: Add link to example PR for Enghouse entity mapping -->

## Step 4: Configure Row-Level Security

Row access policies ensure agencies only see their own data.

### 4.1 Add Enghouse Row Access Policy

Edit `warehouse/macros/create_row_access_policy.sql`:

Find the `payments_enghouse_row_access_policy` macro and add a new entry:

```sql
{{ create_row_access_policy(
    filter_column = 'operator_id',
    filter_value = '<enghouse-operator-id>',
    principals = ['serviceAccount:<agency-slug>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Example:**

```sql
{{ create_row_access_policy(
    filter_column = 'operator_id',
    filter_value = '253',
    principals = ['serviceAccount:vctc-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Note:** The `filter_value` should match exactly what appears in the Enghouse data. In the example above, `'253'` matches the operator_id in the data.

### 4.2 Add Elavon Row Access Policy (if applicable)

If the agency also uses Elavon, find the `payments_elavon_row_access_policy` macro and add:

```sql
{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = '<Elavon Organization Name>',
    principals = ['serviceAccount:<agency-slug>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Example (from actual macro):**

```sql
{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = 'Ventura County Transportation Commission',
    principals = ['serviceAccount:vctc-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

### 4.3 Commit Row Access Policies

```bash
git add warehouse/macros/create_row_access_policy.sql
git commit -m "Add <Agency Name> row access policies"
git push origin onboard-<agency-name>-payments
```

Update your PR, get it reviewed, and merge.

**Example PR:** <!-- TODO: Add link to example PR for Enghouse row access policies -->

## Step 5: Verify Data Pipeline

After all PRs are merged, verify data flows through the pipeline.

### 5.1 Check Raw Data in GCS

```bash
# List raw files
gsutil ls gs://calitp-enghouse-raw/

# Check for agency-specific data
gsutil ls gs://calitp-enghouse-raw/tap/
gsutil ls gs://calitp-enghouse-raw/tx/
```

### 5.2 Verify External Tables

After external tables are created/updated:

```sql
-- In BigQuery, check taps table
SELECT COUNT(*) as row_count
FROM `cal-itp-data-infra.external_enghouse.taps`
WHERE operator_id = '<enghouse-operator-id>';

-- Check transactions table
SELECT COUNT(*) as row_count
FROM `cal-itp-data-infra.external_enghouse.transactions`
WHERE operator_id = '<enghouse-operator-id>';
```

### 5.3 Verify dbt Transformations

After the daily `transform_warehouse` DAG runs:

```sql
-- Check staging layer
SELECT COUNT(*) 
FROM `cal-itp-data-infra.staging_enghouse.taps`
WHERE operator_id = '<enghouse-operator-id>';

-- Check mart layer (final table)
SELECT 
  COUNT(*) as total_transactions,
  MIN(transaction_date) as earliest,
  MAX(transaction_date) as latest
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_enghouse`
WHERE enghouse_operator_id = '<enghouse-operator-id>';
```

### 5.4 Verify Row-Level Security

Test that the service account can only access the agency's data:

```bash
# Authenticate as the service account
gcloud auth activate-service-account \
  --key-file=<agency-slug>-payments-key.json

# Query should return only this agency's data
bq query --use_legacy_sql=false \
  "SELECT enghouse_operator_id, COUNT(*) as count 
   FROM \`cal-itp-data-infra.mart_payments.fct_payments_rides_enghouse\` 
   GROUP BY enghouse_operator_id"

# Should only show one operator_id (the agency's)
```

## Step 6: Set Up Metabase Dashboards

Follow the [Create Agency Metabase Dashboards](create-metabase-dashboards.md) guide with these Enghouse-specific notes:

### Enghouse-Specific Considerations

1. **Database Connection:**

   - Use the same process as Littlepay agencies
   - Service account should have access to `mart_payments` dataset

2. **Dashboard Source:**

   - Use an existing Enghouse agency dashboard as template (if available)
   - Otherwise, adapt from Littlepay dashboard with appropriate field mappings

3. **Key Differences:**

   - Query `fct_payments_rides_enghouse` instead of `fct_payments_rides_v2`
   - Use `enghouse_operator_id` instead of `participant_id`
   - Field names may differ from Littlepay schema

## Troubleshooting

### No Data in External Tables

**Symptoms:** External table query returns 0 rows

**Solutions:**

- Verify data exists in GCS bucket: `gsutil ls gs://calitp-enghouse-raw/`
- Check operator_id format (should match exactly)
- Verify external table definitions point to correct GCS paths
- Check if data delivery from Enghouse is active

### No Data in Mart Tables

**Symptoms:** `fct_payments_rides_enghouse` has no rows for agency

**Solutions:**

- Wait for dbt to run (daily schedule)
- Verify entity mapping exists in `payments_entity_mapping_enghouse.csv`
- Check operator_id is correctly quoted in CSV (e.g., `'253'`)
- Check dbt logs for errors
- Verify row access policy was applied correctly

### Row-Level Security Not Working

**Symptoms:** Service account can see other agencies' data

**Solutions:**

- Verify row access policy was added to macro
- Check operator_id matches exactly (no quotes in macro, quotes in CSV)
- Confirm service account email matches exactly in policy
- Check dbt models were rebuilt after policy change

### Data Schema Differences

**Symptoms:** Queries fail or return unexpected results

**Solutions:**

- Review Enghouse schema documentation
- Compare with Littlepay schema to understand differences
- Check staging models for field mappings
- Consult `warehouse/models/staging/payments/enghouse/` for transformations

## Key Differences: Enghouse vs. Littlepay

| Aspect             | Littlepay                                              | Enghouse                                        |
| ------------------ | ------------------------------------------------------ | ----------------------------------------------- |
| **Identifier**     | `participant_id` / `merchant_id`                       | `operator_id`                                   |
| **Data Access**    | AWS S3 with IAM keys                                   | SFTP to GCS bucket                              |
| **Sync DAG**       | `sync_littlepay_v3`                                    | None (data delivered directly to GCS)           |
| **Data Refresh**   | Hourly                                                 | Daily                                           |
| **Entity Mapping** | `payments_entity_mapping.csv`                          | `payments_entity_mapping_enghouse.csv`          |
| **Mart Table**     | `fct_payments_rides_v2`                                | `fct_payments_rides_enghouse`                   |
| **Tables**         | device_transactions, micropayments, aggregations, etc. | taps, transactions, ticket_results, pay_windows |

## Related Documentation

- [Create Agency Metabase Dashboards](create-metabase-dashboards.md)
- [Onboard a New Littlepay Agency](onboard-littlepay-agency.md) (for comparison)
- [Update Row Access Policies](update-row-access-policies.md) - For understanding row-level security implementation
- [Troubleshoot Data Sync Issues](troubleshoot-sync-issues.md)

______________________________________________________________________

**See Also:** [Tutorial: Your First Agency Onboarding](../tutorials/03-first-agency-onboarding.md) for general onboarding concepts
