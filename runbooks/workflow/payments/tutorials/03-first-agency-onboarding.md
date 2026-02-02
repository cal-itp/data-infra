# Your First Agency Onboarding

**Tutorial Duration:** ~2 hours\
**Prerequisites:** [Understanding the Data Flow](02-understanding-data-flow.md), access to GCP with appropriate permissions\
**What You'll Learn:** How to onboard a new agency to the payments ecosystem through a guided walkthrough

## Introduction

This tutorial walks you through onboarding a fictional agency called "Demo Transit" to the payments ecosystem. You'll learn the complete process from receiving vendor credentials to verifying data in Metabase dashboards.

**Note:** This is a learning tutorial. For production onboarding, use the detailed how-to guides:

- [Onboard a New Littlepay Agency](../how-to/onboard-littlepay-agency.md)
- [Create Agency Metabase Dashboards](../how-to/create-metabase-dashboards.md)

## Scenario

Demo Transit is a small transit agency that has just deployed contactless payment validators on their buses. They're using:

- **Littlepay** for fare collection (instance: `demo-transit`)
- **Elavon** for payment processing (organization: `Demo Transit Authority`)

Your task: Set up the complete data pipeline so Demo Transit can view their payments dashboard.

## Phase 1: Gather Prerequisites

### What You Need

Before starting, collect:

1. **From Littlepay:**

   - AWS access key (JSON format)
   - Merchant ID / participant ID
   - S3 bucket name
   - Confirmation of which tables are available

2. **From Elavon:**

   - Organization name (as it appears in their data files)
   - Confirmation they're in the shared SFTP feed

3. **From Demo Transit:**

   - GTFS dataset identifier (for linking payments to routes/stops)
   - Contact information for dashboard access

4. **Your Access:**

   - GCP project permissions (IAM, Secret Manager, BigQuery)
   - GitHub write access to data-infra repository
   - Terraform permissions (for service account creation)
   - Metabase admin access

### Verify Prerequisites

Let's check you have everything:

```bash
# Check GCP access
gcloud projects list | grep cal-itp-data-infra

# Check GitHub access
gh repo view cal-itp/data-infra

# Check you can access Secret Manager
gcloud secrets list --project=cal-itp-data-infra --limit=5
```

## Phase 2: Set Up AWS Access

### Step 1: Store Littlepay AWS Credentials

You received this JSON from Littlepay:

```json
{
  "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
  "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  "UserName": "demo-transit-default"
}
```

Create a secret in Secret Manager:

```bash
# Create the secret
gcloud secrets create LITTLEPAY_AWS_IAM_DEMO_TRANSIT_ACCESS_KEY \
  --project=cal-itp-data-infra \
  --replication-policy="automatic"

# Add the secret value
echo '{
  "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
  "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  "UserName": "demo-transit-default"
}' | gcloud secrets versions add LITTLEPAY_AWS_IAM_DEMO_TRANSIT_ACCESS_KEY \
  --project=cal-itp-data-infra \
  --data-file=-
```

**Naming Convention:**

- Format: `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY`
- Use uppercase
- Replace hyphens with underscores in merchant_id

### Step 2: Test AWS Access Locally

Configure AWS CLI profile:

```bash
# Configure profile
aws configure --profile demo-transit
# Enter the AccessKeyId when prompted
# Enter the SecretAccessKey when prompted
# Region: us-west-2
# Output format: json

# Test access
aws s3 ls s3://littlepay-demo-transit/ --profile demo-transit
```

You should see directories like:

```
PRE device_transactions/
PRE micropayments/
PRE aggregations/
```

## Phase 3: Create Service Accounts

### Step 1: Create Payments Service Account via Terraform

Create a new branch:

```bash
cd /path/to/data-infra
git checkout -b onboard-demo-transit
```

Edit `iac/cal-itp-data-infra/iam/us/service_account.tf`:

```hcl
# Add this block
resource "google_service_account" "demo_transit_payments_user" {
  account_id   = "demo-transit-payments-user"
  display_name = "Demo Transit Payments User"
  description  = "Service account for Demo Transit payments data access"
  project      = var.project_id
}
```

Edit `iac/cal-itp-data-infra/iam/us/project_iam_member.tf`:

```hcl
# Add this block
resource "google_project_iam_member" "demo_transit_payments_user_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.demo_transit_payments_user.email}"
}
```

Commit and push:

```bash
git add iac/
git commit -m "Add Demo Transit payments service account"
git push origin onboard-demo-transit
```

Create a pull request and get it reviewed and merged.

### Step 2: Download Service Account Key

After the PR is merged and Terraform runs:

```bash
# Create and download key
gcloud iam service-accounts keys create demo-transit-key.json \
  --iam-account=demo-transit-payments-user@cal-itp-data-infra.iam.gserviceaccount.com \
  --project=cal-itp-data-infra
```

**Important:** Store this key securely - you'll need it for Metabase later.

## Phase 4: Configure Data Sync

### Step 1: Create Littlepay Sync Configuration

Create `airflow/dags/sync_littlepay_v3/demo_transit.yml`:

```yaml
operator: operators.LittlepayRawSyncV3
instance: demo-transit
src_bucket: littlepay-datafeed-prod-demo-transit-XXXXXXXX
access_key_secret_name: LITTLEPAY_AWS_IAM_DEMO_TRANSIT_ACCESS_KEY_FEED_V3
```

**Note:** Replace `XXXXXXXX` with the actual bucket suffix from Littlepay.

### Step 2: Create Littlepay Parse Configuration

Create `airflow/dags/parse_littlepay_v3/demo_transit.yml`:

```yaml
operator: operators.LittlepayParsedV3
instance: demo-transit
```

### Step 3: Add Entity Mapping

Edit `warehouse/seeds/payments_entity_mapping.csv`:

```csv
# Add this line
demo-transit,demo_transit_gtfs_dataset_key,Demo Transit,Demo Transit Authority
```

Columns are:

1. Littlepay participant_id
2. Cal-ITP GTFS dataset key
3. Display name
4. Elavon organization name

### Step 4: Commit and Deploy

```bash
git add airflow/dags/sync_littlepay_v3/demo_transit.yml
git add airflow/dags/parse_littlepay_v3/demo_transit.yml
git add warehouse/seeds/payments_entity_mapping.csv
git commit -m "Add Demo Transit sync and parse configurations"
git push origin onboard-demo-transit
```

Create PR, get reviewed, and merge.

## Phase 5: Configure Row-Level Security

### Step 1: Add Row Access Policies

Edit `warehouse/macros/create_row_access_policy.sql`:

Find the `payments_littlepay_row_access_policy` macro and add:

```sql
-- Add after existing entries
UNION ALL
SELECT
  'demo-transit' AS filter_value,
  ['serviceAccount:demo-transit-payments-user@cal-itp-data-infra.iam.gserviceaccount.com'] AS principals
```

Find the `payments_elavon_row_access_policy` macro and add:

```sql
-- Add after existing entries
UNION ALL
SELECT
  'Demo Transit Authority' AS filter_value,
  ['serviceAccount:demo-transit-payments-user@cal-itp-data-infra.iam.gserviceaccount.com'] AS principals
```

Commit and push:

```bash
git add warehouse/macros/create_row_access_policy.sql
git commit -m "Add Demo Transit row access policies"
git push origin onboard-demo-transit
```

Create PR, get reviewed, and merge.

## Phase 6: Verify Data Pipeline

### Step 1: Trigger Sync DAG

After your PRs are merged:

1. Go to Airflow UI
2. Find `sync_littlepay_v3` DAG
3. Trigger it manually (or wait for hourly run)
4. Monitor the logs - look for "demo-transit" tasks

### Step 2: Check Raw Data in GCS

```bash
# List raw files
gsutil ls gs://calitp-payments-littlepay-raw-v3/device-transactions/instance=demo-transit/
```

You should see files partitioned by filename and timestamp.

### Step 3: Verify Parse DAG

1. Wait for `parse_littlepay_v3` to run
2. Check parsed data:

```bash
# List parsed files
gsutil ls gs://calitp-payments-littlepay-parsed-v3/device-transactions/instance=demo-transit/
```

You should see JSONL.gz files.

### Step 4: Check External Tables

After `create_external_tables` runs:

```sql
-- In BigQuery
SELECT COUNT(*) as row_count
FROM `cal-itp-data-infra.external_littlepay.device_transactions`
WHERE participant_id = 'demo-transit';
```

You should see rows!

### Step 5: Wait for dbt Run

After the daily `dbt_daily` DAG runs:

```sql
-- Check staging
SELECT COUNT(*) 
FROM `cal-itp-data-infra.staging.stg_littlepay__device_transactions_v3`
WHERE participant_id = 'demo-transit';

-- Check mart (the final table)
SELECT COUNT(*) 
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id = 'demo-transit';
```

## Phase 7: Set Up Metabase

### Step 1: Create Metabase Database Connection

1. Log into Metabase as admin
2. Go to Settings → Admin Settings → Databases
3. Click "Add database"
4. Configure:
   - **Database type:** BigQuery
   - **Display name:** `Payments - Demo Transit`
   - **Service account JSON file:** Upload `demo-transit-key.json`
   - **Datasets:** Only these...
   - **Dataset names:** `mart_payments`
5. Click "Save"

### Step 2: Create Metabase Group

1. Go to Settings → Admin Settings → People → Groups
2. Click "Create a group"
3. Name: `Payments Group - Demo Transit`
4. Add Demo Transit team members

### Step 3: Create Metabase Collection

1. Exit admin settings
2. Click "+ New" → Collection
3. Name: `Payments Collection - Demo Transit`
4. Save in "Our Analytics"

### Step 4: Set Collection Permissions

1. Go to Settings → Admin Settings → Permissions → Collections
2. Find "Payments Collection - Demo Transit"
3. Set permissions:
   - **Payments Group - Demo Transit:** View
   - **Payments Team:** Curate

### Step 5: Duplicate Dashboard

1. Navigate to an existing agency's collection (e.g., MST)
2. Find "Contactless Payments Metrics Dashboard"
3. Click menu → Duplicate
4. Name: `Contactless Payments Metrics Dashboard (Demo Transit)`
5. Save to: `Payments Collection - Demo Transit`
6. **Uncheck** "Only duplicate the dashboard"

### Step 6: Reconfigure Dashboard Questions

For each question in the duplicated dashboard:

1. Open the question
2. Change the database to "Payments - Demo Transit"
3. Verify the table is still `fct_payments_rides_v2`
4. Save (replace original)

This is tedious but necessary! See the [detailed how-to guide](../how-to/create-metabase-dashboards.md) for specifics.

## Phase 8: Verify End-to-End

### Final Checks

1. **Data Freshness:**

```sql
SELECT 
  MAX(transaction_time) as latest_transaction,
  COUNT(*) as total_transactions
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id = 'demo-transit';
```

2. **Dashboard Access:**

   - Log in as Demo Transit user
   - Navigate to their collection
   - Open the dashboard
   - Verify data displays correctly

3. **Row-Level Security:**

```sql
-- This should return 0 when queried with Demo Transit service account
SELECT COUNT(*)
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id != 'demo-transit';
```

## What You've Learned

Congratulations! You've completed a full agency onboarding. You now understand:

- ✅ How to securely store vendor credentials
- ✅ How to create and configure service accounts
- ✅ How to set up data sync and parse configurations
- ✅ How to configure row-level security
- ✅ How to verify data flows through the pipeline
- ✅ How to set up Metabase dashboards
- ✅ How to verify end-to-end functionality

## Next Steps

Now that you've completed the tutorial:

1. **Review production guides:** Use [Onboard a New Littlepay Agency](../how-to/onboard-littlepay-agency.md) for real onboarding
2. **Learn troubleshooting:** Read [Troubleshoot Data Sync Issues](../how-to/troubleshoot-sync-issues.md)
3. **Understand the architecture:** Study [Payments Ecosystem Overview](../explanation/ecosystem-overview.md)

## Common Pitfalls

**Pitfall 1: Wrong secret name format**

- ❌ `littlepay-aws-demo-transit`
- ✅ `LITTLEPAY_AWS_IAM_DEMO_TRANSIT_ACCESS_KEY`

**Pitfall 2: Forgetting to add entity mapping**

- Without it, payments data won't link to GTFS routes/stops

**Pitfall 3: Not waiting for dbt to run**

- Data won't appear in mart tables until dbt runs (daily)

**Pitfall 4: Metabase database pointing to wrong dataset**

- Must point to `mart_payments`, not `staging`

**Pitfall 5: Not reconfiguring all dashboard questions**

- Every question must be updated to use the new database

## Troubleshooting

**Problem:** Sync DAG fails with "Access Denied"

- Check AWS credentials in Secret Manager
- Verify secret name matches config file
- Test AWS access locally with `aws s3 ls`

**Problem:** No data in external tables

- Check parse DAG ran successfully
- Verify JSONL files exist in GCS parsed bucket
- Check external table definition points to correct GCS path

**Problem:** No data in mart tables

- Wait for dbt to run (daily schedule)
- Check dbt logs in Airflow
- Verify row access policy was applied

**Problem:** Metabase shows "No results"

- Verify dashboard is using correct database
- Check row-level security grants access
- Confirm data exists in BigQuery

______________________________________________________________________

**Previous:** [← Understanding the Data Flow](02-understanding-data-flow.md) | **Up:** [Documentation Home](../README.md)
