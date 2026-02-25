# Onboard a New Enghouse Agency

**Task:** Set up data pipeline for a new agency using Enghouse for fare collection\
**Time Required:** 1-2 hours\
**Prerequisites:** GCP access, GitHub write access

## Overview

This guide walks you through onboarding a new transit agency that uses Enghouse for contactless fare collection. Enghouse is an alternative fare collection provider to Littlepay, used by some Cal-ITP partner agencies.

## Before You Start

### Information Needed

Collect the following before starting:

- [ ] Enghouse operator ID for the agency
- [ ] Agency's GTFS dataset `source_record_id` from `dim_gtfs_datasets` (where `_is_current` is TRUE)
- [ ] Agency's Organization `source_record_id` from `dim_organizations` (where `_is_current` is TRUE)

### Required Access

Verify you have:

- [ ] GCP project `cal-itp-data-infra` access
- [ ] Secret Manager admin permissions
- [ ] GitHub write access to `cal-itp/data-infra`
- [ ] Access to Cal-ITP Enghouse data bucket

### Understanding Enghouse Data

**Key Differences from Littlepay:**

- Enghouse provides data directly to our bucket daily via SFTP delivery mechanism
- Uses `operator_id` instead of `participant_id`
- Different data schema and table structure
- Separate entity mapping file (`payments_entity_mapping_enghouse.csv`)

**Enghouse Tables:**

- `taps` - These are individual “transactions” made by the passenger, meaning each tap of a card on the terminal. Each token (card) can have one or more taps on a given day. (Similar to Littlepay's device-transactions)
- `transactions` - These are authorization operations that are to the Acquirer in connection with each card (similar to Littlepay's micropayments)
- `pay_windows` - payment windows that open with the first tap and close at midnight, one payment window can contain multiple taps, each token (card) has only one payment window per day
- `ticket_results` - Ticket/fare product results

## Step 1: Understand and Verify Data Delivery Method

**Enghouse Data Delivery:**

Enghouse delivers data daily via SFTP server directly to our GCS bucket. This differs from Littlepay's S3-based approach, which requires us to run a daily sync task on our end to copy to our raw data bucket.

**Implementation Details:**

- Data is delivered directly to `gs://calitp-enghouse-raw/` via SFTP
- No sync DAG is needed (data arrives directly in GCS)
- External tables read from `gs://calitp-enghouse-raw/`
- Data refresh: Daily

**For New Agency Onboarding:**

1. Coordinate with Enghouse to set up SFTP delivery for the new agency
2. Verify data appears in `gs://calitp-enghouse-raw/` after delivery is configured
3. Confirm the agency's `operator_id` in the delivered data

### 1.1 Verify Raw Data in GCS

1. Navigate to Google Cloud Storage
2. Select the bucket `cal-itp-data-infra-enghouse-raw`
3. Select any table directory from the list, ex: `tap/`
4. Select the directory of the agency whose sync task you are verifying, ex: `ventura/`
5. You should see at least one file within that directory, ex: `cal-itp-data-infra-enghouse-raw/tap/ventura/VENTURA_TAPtaps-2025-12-14.csv`

## Step 2: Create Service Account

The agency needs a dedicated service account for accessing their payments data with row-level security.

**Reference PR:** [#4638](https://github.com/cal-itp/data-infra/pull/4638)

### 2.1 Create Service Account via Terraform

Create a new branch, ex: `payments-service-account-<agency-name>`

**Edit `iac/cal-itp-data-infra/iam/us/service_account.tf`:**

Add a new service account resource (use existing entries as reference), replacing <agency> in the below fields with the appropriate agency name:

```hcl
resource "google_service_account" "<agency>-payments-user" {
  account_id = "<agency>-payments-user"
  disabled   = "false"
  project    = "cal-itp-data-infra"
}
```

**Edit `iac/cal-itp-data-infra/iam/us/project_iam_member.tf`:**

Add BigQuery user role binding, replacing <agency> in the below fields with the appropriate agency name:

```hcl
resource "google_project_iam_member" "tfer--projects-002F-cal-itp-data-infra-002F-roles-002F-AgencyPaymentsServiceReaderserviceAccount-003A-<agency>-payments-user-0040-cal-itp-data-infra-002E-iam-002E-gserviceaccount-002E-com" {
  member  = "serviceAccount:<agency>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com"
  project = "cal-itp-data-infra"
  role    = "projects/cal-itp-data-infra/roles/AgencyPaymentsServiceReader"
}
```

### 2.2 Commit and Create PR, Ensure Terraform Github Actions Succeed

Create a pull request, get it reviewed, and merge. Make sure Terraform Github Actions pass.

### 2.3 Verify Service Account Creation

After the PR is merged and GitHub Actions succeed:

1. Navigate to [IAM & Admin/ IAM](https://console.cloud.google.com/iam-admin/?project=cal-itp-data-infra)
2. Verify `<agency>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com` exists and has role `Agency Payments Service Reader`

### 2.4 Generate Service Account Key

**Important:** You'll need this key for Metabase configuration later.

1. Navigate to [IAM & Admin/ Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=cal-itp-data-infra)
2. Click into the service account that you just created
3. Navigate into the `Keys` section of the top menu
4. Select `Add Key` --> `Select New Key` from the dropdown menu and select `JSON` as the format
5. Download the key to a secure location locally

Store this file securely. You'll upload it to Metabase in a later step.

## Step 3: Add Entity Mapping

Enghouse agencies use their own entity mapping file.

**Reference PR:** In [#4658](https://github.com/cal-itp/data-infra/pull/4658/changes#diff-96699f2c585fc26b7b38248a1a1e220578588e391201086b7ce5020db0c7ad96R2)

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

1. **gtfs_dataset_source_record_id** - The `source_record_id` from `dim_gtfs_datasets` for the agency's GTFS feed where `_is_current` is TRUE
2. **organization_source_record_id** - The `source_record_id` from `dim_organizations` for the agency where `_is_current` is TRUE
3. **enghouse_operator_id** - Operator ID from Enghouse (no quotes in CSV)
4. **elavon_customer_name** - Agency `customer_name` as it appears in Elavon data
5. **\_in_use_from** & **\_in_use_until**

- These columns were added for the very rare circumstances when an agency's Elavon `customer_name` changes over time (as of this writing this only applies to sacrt)
- For those agencies, align `_in_use_from` and `_in_use_until` dates to the `customer_name` cutover
- For agencies where this doesn't apply, use arbitrary distant `_in_use_from` and `_in_use_until` dates such as `2000-01-01`and `2099-12-31`

**To find the source_record_ids:**
Unfortunately, these are somewhat manual processes. Use the queries below to filter the results down, and then manually page through the results until you find the `name` value of the agency that you are looking for. Once you've found the correct name, copy that `source_record_id` for that row.

**Note:**

- When in doubt, reach out to the customer success team for clarity around the expected Organization and GTFS Feed names for the agency.

```sql
-- Find GTFS dataset source_record_id
SELECT source_record_id, name
FROM `cal-itp-data-infra.mart_transit_database.dim_gtfs_datasets`
WHERE _is_current = TRUE
ORDER BY name ASC -- or DESC, depending on the agency's name is towards the front or end of the alphabet

-- Find organization source_record_id
SELECT source_record_id, name
FROM `cal-itp-data-infra.mart_transit_database.dim_organizations`
WHERE _is_current = TRUE
ORDER BY name ASC -- or DESC, depending on the agency's name is towards the front or end of the alphabet
```

### 3.2 Commit Entity Mapping

Update your existing PR or create a new one. Get it reviewed and merged.

## Step 4: Configure Row-Level Security

Row access policies ensure agencies only see their own data when querying through their service account.

**Example PR:** In [#4658](https://github.com/cal-itp/data-infra/pull/4658/changes#diff-e32013136795892ab542f0571294fd65e723bc4085e41b5a52ac75d29e3503e4R207)

### 4.1 Add Enghouse Row Access Policy

Edit `warehouse/macros/create_row_access_policy.sql`:

Find the `payments_enghouse_row_access_policy` macro and add a new entry, using previous entries as a template:

**Example:**

```sql
{{ create_row_access_policy(
    filter_column = 'operator_id',
    filter_value = '<enghouse_operator_id',
    principals = ['serviceAccount:<agency>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Note:**

- The Enghouse `operator_id` above must match what appears in the data, although you must add quotes around the ID to handle it as a string
- The service account name within `principals` must match the name of the service account created in step 2.

### 4.2 Add Elavon Row Access Policy

If the agency also uses Elavon, find the `payments_elavon_row_access_policy` macro and add a new entry, using previous entries as a template:

```sql
{{ create_row_access_policy(
    filter_column = 'organization_name',
    filter_value = '<elavon_organization_name>',
    principals = ['serviceAccount:<agency>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Notes:**

- The service account name within `principals` must match the name of the service account created in step 2.
- By using `organization_name` here, as opposed to Elavon `customer_name`, we make the organization's Elavon transaction history available, as opposed to just the history for a single `customer_name` for those agencies who have changed customer names over time.

### 4.3 Commit Row Access Policies

Update your PR, get it reviewed, and merge.

## Step 5: Verify Data Pipeline

After all PRs are merged, verify data flows through the pipeline.

### 5.1 Verify External Tables

In BigQuery, query:

```sql
-- In BigQuery
SELECT COUNT(*) as row_count
FROM `cal-itp-data-infra.external_enghouse.taps`
WHERE operator_id = '<enghouse-operator-id>'
```

### 5.2 Verify dbt Transformations

After the next scheduled run of the transform_warehouse DAG:

```sql
-- Check staging table
SELECT COUNT(*) 
FROM `cal-itp-data-infra.staging.stg_enghouse__taps`
WHERE operator_id = '<enghouse-operator-id>';

-- Check mart table
SELECT 
  COUNT(*) as total_transactions,
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_enghouse`
WHERE operator_id = '<enghouse-operator-id>';
```

## Step 6: Next Steps

After completing Littlepay onboarding:

1. **Set up Metabase dashboards:** Follow [Create Agency Metabase Dashboards](create-metabase-dashboards.md)
2. **Onboard Elavon (if applicable):** Follow [Onboard a New Elavon Agency](onboard-elavon-agency.md)
3. **Monitor the pipeline:** Use [Troubleshoot Data Sync Issues](troubleshoot-sync-issues.md) for ongoing monitoring

## Troubleshooting

### No Data in External Tables

**Symptoms:** External table query returns 0 rows

**Solutions:**

- Verify data exists in GCS bucket
- Check if data delivery from Enghouse is active

### No Data in Mart Tables

**Symptoms:** `fct_payments_rides_enghouse` has no rows for agency

**Solutions:**

- Wait for all upstream dependencies to run - particularly transform tasks
  - Make sure that there haven't been changes to the scheduling of any of these DAGs, as the timing and order that they run in is crucial to data availability when expected
- Check operator_id is not quoted in entity mapping CSV (e.g., `'253'`), but is quoted in row access policy macro
- Check DAG logs for errors
- Verify row access policy was applied correctly

### Row-Level Security Not Working

**Symptoms:** Service account can see other agencies' data

**Solutions:**

- Verify row access policy was added to macro
- Check operator_id is not quoted in entity mapping CSV (e.g., `'253'`), but is quoted in row access policy macro
- Confirm service account email matches exactly in policy
- Check dbt models were rebuilt after policy change

### Data Schema Differences

**Symptoms:** Queries fail or return unexpected results

**Solutions:**

- Review Enghouse schema documentation
- Compare with Littlepay schema to understand differences
- Consult `warehouse/models/mart/payments/enghouse/` and other upstream models for transformations etc.

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

- [Update Row Access Policies](update-row-access-policies.md) - For understanding row-level security implementation
- [Create Agency Metabase Dashboards](create-metabase-dashboards.md)
- [Rotate Littlepay AWS Keys](rotate-littlepay-keys.md)
- [Troubleshoot Data Sync Issues](troubleshoot-sync-issues.md)

______________________________________________________________________

**See Also:** [Tutorial: Your First Agency Onboarding](../tutorials/03-first-agency-onboarding.md) for general onboarding concepts
