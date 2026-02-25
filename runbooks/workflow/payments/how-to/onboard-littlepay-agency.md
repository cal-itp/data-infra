# Onboard a New Littlepay Agency

**Task:** Set up data pipeline for a new agency using Littlepay for fare collection\
**Time Required:** 1-2 hours\
**Prerequisites:** GCP access, GitHub write access

## Overview

This guide walks you through onboarding a new transit agency that uses Littlepay for contactless fare collection. You'll configure data syncing, parsing, and access controls.

## Before You Start

### Information Needed

Collect the following before starting:

- [ ] Littlepay AWS access key (JSON format)
- [ ] Participant ID (e.g., `mst`, `sbmtd`)
- [ ] S3 bucket name from Littlepay
- [ ] Agency's GTFS dataset `source_record_id` from `dim_gtfs_datasets` (where `_is_current` is TRUE)
- [ ] Agency's Organization `source_record_id` from `dim_organizations` (where `_is_current` is TRUE)

### Required Access

Verify you have:

- [ ] GCP project `cal-itp-data-infra` access
- [ ] Secret Manager admin permissions
- [ ] GitHub write access to `cal-itp/data-infra`
- [ ] AWS CLI installed locally (to view data in Littlepay's buckets, as necessary)
- [ ] Access to Cal-ITP Littlepay raw and parsed data buckets

## Step 1: Store AWS Credentials

### 1.1 Receive Credentials from Littlepay

Littlepay should reach out to their Cal-ITP contacts when an agency's credentials are available. The credentials should inclide:

- UserName (different from participant_id)
- AccessKeyId
- SecretAccessKey

Example credentials:

```json
{
    "AccessKey": {
        "UserName": "agency-automated",
        "AccessKeyId": "AAA111BBBB222CCC333",
        "Status": "Active",
        "SecretAccessKey": "ghuq24jrbehgRG35Gerwg432DSFG",
        "CreateDate": "manual"
    }
}
```

You can use the above example when creating a new JSON key in Secret Manager, or use an existing key as the base template.

### 1.2 Create Secret in Secret Manager

**Naming Convention:** `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY_FEED_V3`

- Use UPPERCASE
- Replace hyphens with underscores in merchant_id
- Example: `mst` → `LITTLEPAY_AWS_IAM_MST_ACCESS_KEY_FEED_V3`

**Via GCP Console:**

1. Navigate to [Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra)
2. Click "Create Secret"
3. Name: `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY_FEED_V3`
4. Secret value: Paste the entire JSON
5. Click "Create Secret"

### 1.3 Verify AWS Access

Test the credentials locally:

```bash
# Configure AWS CLI profile, UserName should be the same as in the AccessKey credentials above (different from participant_id!)
aws configure --profile <Littlepay UserName>
# Enter AccessKeyId when prompted
# Enter SecretAccessKey when prompted
# Region: us-west-2
# Output format: json

# Test listing S3 bucket contents
aws s3 ls s3://<littlepay-bucketname> --profile <Littlepay UserName>
```

**Expected output:**
You should see the contents of the bucket - a list of files and dates.

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

## Step 3: Configure Data Sync

### 3.1 Create Sync Configuration

Create `airflow/dags/sync_littlepay_v3/<agency>.yml`:

Use another agency's yml as the template for this DAG. The final DAG yml should look like this:

```yaml
operator: operators.LittlepayRawSyncV3
instance: <agency>
src_bucket: <littlepay-AWS-bucket-name>
access_key_secret_name: LITTLEPAY_AWS_IAM_<agency>_ACCESS_KEY_FEED_V3
```

Where `instance` and `src_bucket` are the values that we received from Littlepay, and `access_key_secret_name` is the name of the secret that we created in Step 1.2.

**Notes:**

- `instance` and `src_bucket` must match the values received from Littlepay
- `access_key_secret_name` must match the secret created in Step 1

### 3.2 Create Parse Configuration

Create `airflow/dags/parse_littlepay_v3/<agency>.yml`:

Use another agency's yml as the template for this DAG. The final DAG yml should look like this:

```yaml
operator: operators.LittlepayToJSONLV3
instance: <agency>
```

Where `instance` is the value that we received from Littlepay.

**Note:**

- `instance` must match the value received from Littlepay

## 4. Add Entity Mapping

Littlepay agencies use their own entity mapping file.

**Reference PR:** [#4375](https://github.com/cal-itp/data-infra/pull/4375)

### 4.1 Edit Entity Mapping

Edit `warehouse/seeds/payments_entity_mapping.csv`:

Add a new row:

```csv
<gtfs-dataset-source-record-id>,<organization-source-record-id>,<littlepay-participant-id>,<elavon-customer-name>,<_in_use_from>,<_in_use_until>
```

**Example (from actual file):**

```csv
recysP9m9kjCJwHZe,receZJ9sEnP9vy3g0,mst,MST TAP TO RIDE,2000-01-01,2099-12-31
```

**Column Definitions:**

1. **gtfs_dataset_source_record_id** - The `source_record_id` from `dim_gtfs_datasets` for the agency's GTFS feed where `_is_current` is TRUE
2. **organization_source_record_id** - The `source_record_id` from `dim_organizations` for the agency where `_is_current` is TRUE
3. **littlepay_participant_id** - The `participant_id` from Littlepay
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

### 4.2 Commit Entity Mapping

Update your existing PR or create a new one. Get it reviewed and merged.

## Step 5: Configure Row-Level Security

Row access policies ensure agencies only see their own data when querying through their service account. These policies are applied via post-hook in the tables in the **mart** layer.

**Example PR:** [#4376](https://github.com/cal-itp/data-infra/pull/4376)

### 5.1 Add Littlepay Row Access Policy

Edit `warehouse/macros/create_row_access_policy.sql`:

Find the `payments_littlepay_row_access_policy` macro and add a new entry, using previous entries as a template:

**Example:**

```sql
{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = '<littlepay_participant_id>',
    principals = ['serviceAccount:<agency>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

**Notes:**

- The Littlepay `participant_id` above must match exactly what appears in the data
- The service account name within `principals` must exactly match the name of the service account created in step 2.

**Reference PR:** [#4376](https://github.com/cal-itp/data-infra/pull/4376)

### 5.2 Add Elavon Row Access Policy

If the agency also uses Elavon, find the `payments_elavon_row_access_policy` macro and add a new entry, using previous entries as a template:

**Example:**

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

### 5.3 Commit Row Access Policies

Update your PR, get it reviewed, and merge.

## Step 6: Verify Data Pipeline

After all PRs are merged, actions have succeeded, and relevant DAGs have run, verify data flows through the pipeline.

### 6.1 Verify Sync DAG

Once the PR that contains your new sync task has been merged, and the time of the next scheduled DAG run has passed:

1. Navigate to the Airflow UI
2. Find `sync_littlepay_v3` DAG, click into it
3. Find the new task that was created in your PR, and ensure that the run shows as a green 'success'.

### 6.2 Check Raw Data in GCS

1. Navigate to Google Cloud Storage
2. Select the bucket `calitp-payments-littlepay-raw-v3`
3. Select any table directory from the list, ex: `micropayments/`
4. Select the directory of the agency whose sync task you are verifying, ex: `instance=mst/`
5. You should see at least one file within that directory, ex: `calitp-payments-littlepay-raw-v3/micropayments/instance=mst/filename=202505081110_micropayments.psv`

### 6.3 Verify Parse DAG

Once the PR that contains your new sync task has been merged, the time of the next scheduled sync DAG run has passed, and the time of the next scheduled parse DAG run has passed:

1. Navigate to the Airflow UI
2. Find `parse_littlepay_v3` DAG, click into it
3. Find the new task that was created in your PR, and ensure that the run shows as a green 'success'.

### 6.4 Check Parsed Data in GCS

1. Navigate to Google Cloud Storage
2. Select the bucket `calitp-payments-littlepay-parsed-v3`
3. Select any table directory from the list, ex: `micropayments`
4. Select the directory of the agency whose sync task you are verifying, ex: `instance=mst/`
5. You should see at least one file within that directory, ex: `calitp-payments-littlepay-parsed-v3/micropayments/instance=mst/extract_filename=202504301116_micropayments.psv`

### 6.5 Verify External Tables

In BigQuery, query:

```sql
SELECT COUNT(*) as row_count
FROM `cal-itp-data-infra.external_littlepay_v3.device_transactions`
WHERE participant_id = '<littlepay-participant-id>'
```

### 6.6 Verify dbt Transformations

After the next scheduled run of the transform_warehouse DAG:

```sql
-- Check staging table
SELECT COUNT(*) 
FROM `cal-itp-data-infra.staging.stg_littlepay__micropayments_v3`
WHERE participant_id = '<littlepay-participant-id>'

-- Check mart table
SELECT 
  COUNT(*) as total_transactions,
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id = '<littlepay-participant-id>'
```

## Step 7: Next Steps

After completing Littlepay onboarding:

1. **Set up Metabase dashboards:** Follow [Create Agency Metabase Dashboards](create-metabase-dashboards.md)
2. **Onboard Elavon (if applicable):** Follow [Onboard a New Elavon Agency](onboard-elavon-agency.md)
3. **Monitor the pipeline:** Use [Troubleshoot Data Sync Issues](troubleshoot-sync-issues.md) for ongoing monitoring

## Troubleshooting

### Sync DAG Fails with "Access Denied"

**Symptoms:** Sync DAG fails with AWS access denied error

**Solutions:**

- Verify secret name in YAML matches Secret Manager
- Verify secret contents match what we received from Littlepay
- Verify `instance` matches what we received from Littlepay
- Verify `src_bucket` matches what we received from Littlepay
- Check AWS credentials work in CLI: `aws s3 ls s3://<littlepay-bucket-name>/ --profile <Littlepay UserName>`

### No Data in External Tables

**Symptoms:** External table query returns 0 rows

**Solutions:**

- Verify sync and parse DAGs ran successfully
- Check files exist in the raw and parsed buckets

### No Data in Mart Tables

**Symptoms:** `fct_payments_rides_v2` has no rows for agency

**Solutions:**

- Wait for all upstream dependencies to run - sync, parse, and transform tasks
  - Make sure that there haven't been changes to the scheduling of any of these DAGs, as the timing and order that they run in is crucial to data availability when expected
- Check DAG logs for errors
- Verify row access policy was applied correctly

### Row-Level Security Not Working

**Symptoms:** Service account can see other agencies' data

**Solutions:**

- Verify row access policy was added to macro
- Verify row access policy post-hook exists at the top of the table SQL that you're trying to protect
- Check dbt models were rebuilt after policy change
- Confirm service account email, filters match exactly in policy

### Data Schema Differences

**Symptoms:** Queries fail or return unexpected results

**Solutions:**

- Review Littlepay schema documentation
- Compare with Enghouse schema to understand differences
- Consult `warehouse/models/mart/payments/littlepay/` and other upstream models for transformations etc.

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
