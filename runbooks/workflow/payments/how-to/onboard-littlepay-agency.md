# Onboard a New Littlepay Agency

**Task:** Set up data pipeline for a new agency using Littlepay for fare collection\
**Time Required:** 1-2 hours\
**Prerequisites:** GCP access, GitHub write access, Terraform permissions

## Overview

This guide walks you through onboarding a new transit agency that uses Littlepay for contactless fare collection. You'll configure data syncing, parsing, and access controls.

## Before You Start

### Information Needed

Collect the following before starting:

- [ ] Littlepay AWS access key (JSON format)
- [ ] Merchant ID / participant ID (e.g., `mst`, `sbmtd`)
- [ ] S3 bucket name (usually `littlepay-<merchant_id>`)
- [ ] Agency's GTFS dataset `source_record_id` from `dim_gtfs_datasets` (where `_is_current` is TRUE)
- [ ] Agency contact information for dashboard access

### Required Access

Verify you have:

- [ ] GCP project `cal-itp-data-infra` access
- [ ] Secret Manager admin permissions
- [ ] GitHub write access to `cal-itp/data-infra`
- [ ] Terraform apply permissions (for service account creation)
- [ ] AWS CLI installed locally

## Step 1: Store AWS Credentials

### 1.1 Receive Credentials from Littlepay

Contact `support@littlepay.com` to request access to the agency's data feed. You'll receive an email with:

- Support ticket reference
- AWS access key (JSON format)
- Username (may differ from merchant_id)

Example credentials:

```json
{
  "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
  "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  "UserName": "agency-name-default"
}
```

### 1.2 Create Secret in Secret Manager

**Naming Convention:** `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY`

- Use UPPERCASE
- Replace hyphens with underscores in merchant_id
- Example: `mst` → `LITTLEPAY_AWS_IAM_MST_ACCESS_KEY`

**Via GCP Console:**

1. Navigate to [Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra)
2. Click "Create Secret"
3. Name: `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY`
4. Secret value: Paste the entire JSON
5. Click "Create Secret"

**Via gcloud CLI:**

```bash
# Create the secret
gcloud secrets create LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY \
  --project=cal-itp-data-infra \
  --replication-policy="automatic"

# Add the secret value (replace with actual JSON)
echo '{
  "AccessKeyId": "...",
  "SecretAccessKey": "...",
  "UserName": "..."
}' | gcloud secrets versions add LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY \
  --project=cal-itp-data-infra \
  --data-file=-
```

### 1.3 Verify AWS Access

Test the credentials locally:

```bash
# Configure AWS CLI profile
aws configure --profile <merchant_id>
# Enter AccessKeyId when prompted
# Enter SecretAccessKey when prompted
# Region: us-west-2
# Output format: json

# Test access
aws iam list-access-keys --user-name <username> --profile <merchant_id>

# List S3 bucket contents
aws s3 ls s3://littlepay-<merchant_id>/ --profile <merchant_id>
```

**Expected output:**

```
PRE device_transactions/
PRE micropayments/
PRE micropayment_adjustments/
PRE aggregations/
PRE settlements/
PRE customer_funding_source/
PRE products/
```

**Note:** The username may differ from merchant_id. Check error messages for the actual username if the command fails.

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

Add a new service account resource (use existing entries as reference):

```hcl
resource "google_service_account" "<agency>_payments_user" {
  account_id   = "<merchant-id>-payments-user"
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

**Reference PR:** [#4374](https://github.com/cal-itp/data-infra/pull/4374/files)

### 2.2 Commit and Create PR

```bash
git add iac/cal-itp-data-infra/iam/us/service_account.tf
git add iac/cal-itp-data-infra/iam/us/project_iam_member.tf
git commit -m "Add <Agency Name> payments service account"
git push origin onboard-<agency-name>-payments
```

Create a pull request, get it reviewed, and merge.

### 2.3 Verify Service Account Creation

After the PR is merged and GitHub Actions complete:

1. Navigate to [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=cal-itp-data-infra)
2. Verify `<merchant-id>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com` exists

### 2.4 Download Service Account Key

**Important:** You'll need this key for Metabase configuration later.

```bash
gcloud iam service-accounts keys create <merchant-id>-payments-key.json \
  --iam-account=<merchant-id>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com \
  --project=cal-itp-data-infra
```

Store this file securely. You'll upload it to Metabase in a later step.

## Step 3: Configure Data Sync

### 3.1 Create Sync Configuration

Create `airflow/dags/sync_littlepay_v3/<merchant_id>.yml`:

```yaml
name: <merchant-id>
merchant_id: <merchant-id>
aws_credentials_secret_name: LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY
tables:
  - device_transactions
  - micropayments
  - micropayment_adjustments
  - aggregations
  - settlements
  - customer_funding_source
  - products
```

**Notes:**

- `name` and `merchant_id` should match
- `aws_credentials_secret_name` must match the secret created in Step 1
- Include all tables available in the agency's S3 bucket

### 3.2 Create Parse Configuration

Create `airflow/dags/parse_littlepay_v3/<merchant_id>.yml`:

```yaml
name: <merchant-id>
merchant_id: <merchant-id>
tables:
  - device_transactions
  - micropayments
  - micropayment_adjustments
  - aggregations
  - settlements
  - customer_funding_source
  - products
```

**Note:** Table list should match the sync configuration.

### 3.3 Add Entity Mapping

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

1. **gtfs_dataset_source_record_id** - The `source_record_id` from `dim_gtfs_datasets` where `_is_current` is TRUE
2. **organization_source_record_id** - The `source_record_id` from `dim_organizations` for the agency
3. **littlepay_participant_id** - The merchant_id/participant_id from Littlepay
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

### 3.4 Commit Configuration Files

```bash
git add airflow/dags/sync_littlepay_v3/<merchant_id>.yml
git add airflow/dags/parse_littlepay_v3/<merchant_id>.yml
git add warehouse/seeds/payments_entity_mapping.csv
git commit -m "Add <Agency Name> Littlepay sync and parse configurations"
git push origin onboard-<agency-name>-payments
```

Update your existing PR or create a new one. Get it reviewed and merged.

**Reference PR:** [#2928](https://github.com/cal-itp/data-infra/pull/2928/files)

## Step 4: Configure Row-Level Security

Row access policies ensure agencies only see their own data when querying through their service account.

### 4.1 Add Littlepay Row Access Policy

Edit `warehouse/macros/create_row_access_policy.sql`:

Find the `payments_littlepay_row_access_policy` macro and add a new entry:

```sql
UNION ALL
SELECT
  '<littlepay-participant-id>' AS filter_value,
  ['serviceAccount:<merchant-id>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com'] AS principals
```

**Example:**

```sql
UNION ALL
SELECT
  'mst' AS filter_value,
  ['serviceAccount:mst-payments-user@cal-itp-data-infra.iam.gserviceaccount.com'] AS principals
```

### 4.2 Add Elavon Row Access Policy (if applicable)

If the agency also uses Elavon, find the `payments_elavon_row_access_policy` macro and add:

```sql
UNION ALL
SELECT
  '<Elavon Organization Name>' AS filter_value,
  ['serviceAccount:<merchant-id>-payments-user@cal-itp-data-infra.iam.gserviceaccount.com'] AS principals
```

**Example:**

```sql
UNION ALL
SELECT
  'Monterey-Salinas Transit' AS filter_value,
  ['serviceAccount:mst-payments-user@cal-itp-data-infra.iam.gserviceaccount.com'] AS principals
```

### 4.3 Commit Row Access Policies

```bash
git add warehouse/macros/create_row_access_policy.sql
git commit -m "Add <Agency Name> row access policies"
git push origin onboard-<agency-name>-payments
```

Update your PR, get it reviewed, and merge.

**Reference PR:** [#4376](https://github.com/cal-itp/data-infra/pull/4376/files)

**Note:** The row access policy macro is now centralized. Previously, it was defined in individual model files.

## Step 5: Verify Data Pipeline

After all PRs are merged, verify data flows through the pipeline.

### 5.1 Trigger Sync DAG

1. Navigate to [Airflow UI](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/sync_littlepay/grid)
2. Find `sync_littlepay_v3` DAG
3. Trigger manually or wait for hourly schedule
4. Monitor logs for your agency's tasks

### 5.2 Check Raw Data in GCS

```bash
# List raw files
gsutil ls gs://calitp-littlepay-raw/<merchant-id>/device_transactions/

# Check file contents (optional)
gsutil cat gs://calitp-littlepay-raw/<merchant-id>/device_transactions/dt=<date>/ts=<timestamp>/device_transactions.csv | head
```

### 5.3 Verify Parse DAG

1. Navigate to [Parse DAG](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/parse_littlepay/grid)
2. Wait for `parse_littlepay_v3` to run (hourly, after sync)
3. Check parsed data:

```bash
# List parsed files
gsutil ls gs://calitp-littlepay-parsed/<merchant-id>/device_transactions/

# Check file format (should be JSONL.gz)
gsutil cat gs://calitp-littlepay-parsed/<merchant-id>/device_transactions/<path>/*.jsonl.gz | gunzip | head
```

### 5.4 Verify External Tables

After [create_external_tables DAG](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/create_external_tables/grid) runs:

```sql
-- In BigQuery
SELECT COUNT(*) as row_count
FROM `cal-itp-data-infra.external_littlepay.device_transactions`
WHERE participant_id = '<littlepay-participant-id>';
```

### 5.5 Verify dbt Transformations

After [transform_warehouse DAG](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/transform_warehouse/grid) runs (daily):

```sql
-- Check staging layer
SELECT COUNT(*) 
FROM `cal-itp-data-infra.staging_littlepay.device_transactions`
WHERE participant_id = '<littlepay-participant-id>';

-- Check mart layer (final table)
SELECT 
  COUNT(*) as total_transactions,
  MIN(transaction_time) as earliest,
  MAX(transaction_time) as latest
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id = '<littlepay-participant-id>';
```

### 5.6 Verify Row-Level Security

Test that the service account can only access the agency's data:

```bash
# Authenticate as the service account
gcloud auth activate-service-account \
  --key-file=<merchant-id>-payments-key.json

# Query should return only this agency's data
bq query --use_legacy_sql=false \
  "SELECT participant_id, COUNT(*) as count 
   FROM \`cal-itp-data-infra.mart_payments.fct_payments_rides_v2\` 
   GROUP BY participant_id"

# Should only show one participant_id (the agency's)
```

## Step 6: Next Steps

After completing Littlepay onboarding:

1. **Set up Metabase dashboards:** Follow [Create Agency Metabase Dashboards](create-metabase-dashboards.md)
2. **Onboard Elavon (if applicable):** Follow [Onboard a New Elavon Agency](onboard-elavon-agency.md)
3. **Monitor the pipeline:** Use [Troubleshoot Data Sync Issues](troubleshoot-sync-issues.md) for ongoing monitoring

## Troubleshooting

### Sync DAG Fails with "Access Denied"

**Symptoms:** Sync DAG fails with AWS access denied error

**Solutions:**

- Verify secret name in YAML matches Secret Manager
- Check AWS credentials are valid: `aws s3 ls s3://littlepay-<merchant-id>/ --profile <merchant-id>`
- Confirm username in credentials matches actual AWS username
- Check secret has been granted to Airflow service account

### No Data in External Tables

**Symptoms:** External table query returns 0 rows

**Solutions:**

- Verify parse DAG ran successfully
- Check JSONL files exist: `gsutil ls gs://calitp-littlepay-parsed/<merchant-id>/`
- Verify external table definition points to correct GCS path
- Check for parsing errors in Airflow logs

### No Data in Mart Tables

**Symptoms:** `fct_payments_rides_v2` has no rows for agency

**Solutions:**

- Wait for dbt to run (daily schedule, check transform_warehouse DAG)
- Verify entity mapping exists in `payments_entity_mapping.csv`
- Check dbt logs for errors
- Verify row access policy was applied correctly

### Row-Level Security Not Working

**Symptoms:** Service account can see other agencies' data

**Solutions:**

- Verify row access policy was added to macro
- Check dbt models were rebuilt after policy change
- Confirm service account email matches exactly in policy
- Test with correct service account credentials

## Related Documentation

- [Create Agency Metabase Dashboards](create-metabase-dashboards.md)
- [Rotate Littlepay AWS Keys](rotate-littlepay-keys.md)
- [Troubleshoot Data Sync Issues](troubleshoot-sync-issues.md)
- [Update Row Access Policies](update-row-access-policies.md) - For understanding row-level security implementation

______________________________________________________________________

**See Also:** [Tutorial: Your First Agency Onboarding](../tutorials/03-first-agency-onboarding.md) for a guided walkthrough
