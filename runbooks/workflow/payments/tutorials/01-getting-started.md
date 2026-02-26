# Getting Started with the Payments Data Ecosystem

**Tutorial Duration:** ~30 minutes\
**Prerequisites:** Access to Cal-ITP GCP project, basic understanding of data pipelines\
**What You'll Learn:** The fundamentals of the Cal-ITP payments data ecosystem and how to navigate it

## Introduction

Welcome to the Cal-ITP payments data ecosystem! This tutorial will guide you through the basics of how contactless payments data flows through our system, from transit riders tapping their cards to agencies viewing their dashboard metrics.

By the end of this tutorial, you'll understand:

- What the payments data ecosystem does
- The key components and how they connect
- Where to find important resources
- How to verify the system is working

## What is the Payments Data Ecosystem?

The Cal-ITP payments data ecosystem ingests, processes, and utilizes contactless payment data for transit agencies across California. When a rider taps their credit card, phone, or smartwatch on a validator:

1. The validator sends the tap to the fare collection processor (Littlepay or Enghouse, depending on who the agency has contracted)
2. Littlepay or Enghouse calculates the fare and processes the payment through a payment processor (Elavon)
3. These relevant vendors provide data files to Cal-ITP, depending on who the agency has contracted
4. Our data pipeline ingests, transforms, reconciles, and presents this data to agencies

## Step 1: Explore the System Components

Let's walk through each component:

### Data Vendors

**Littlepay** - A fare collection processor (used by some agencies)

- Receives tap events from validators
- Calculates fares (flat fare or variable fare based on distance/zones)
- Manages fare capping, different fare products, benefits, and customer accounts
- Provides data via AWS S3 buckets, which we read and copy from

**Enghouse** - A fare collection processor (used by some agencies)

- Receives tap events from validators
- Calculates fares (flat fare or variable fare based on distance/zones)
- Manages fare capping, different fare products, benefits, and customer accounts
- Provides data directly to our GCS buckets via SFTP server

**Elavon** - A payment processor (currently used by all agencies)

- Processes actual credit/debit card transactions
- Handles settlements, refunds, and deposits
- Provides data via SFTP server

### Data Pipeline

Navigate to the GCP Composer/ Airflow UI (link in your onboarding docs) and find these DAGs:

**For Littlepay agencies:**

1. **sync_littlepay_v3** - Downloads raw data from Littlepay's S3 buckets
2. **parse_littlepay_v3** - Converts and processes raw data to BigQuery-compatible format

**For Enghouse agencies:**

- Enghouse data is delivered directly to GCS (no sync DAG needed)

**For Elavon agencies:**

1. **sync_elavon** - Downloads raw data from Elavon's SFTP server
2. **parse_elavon** - Converts and processes Elavon data to BigQuery-compatible format

**For all agencies:**

1. **create_external_tables** - Creates BigQuery external tables from raw or parsed data
2. **dbt_daily** - Runs dbt models to transform data into analytics-ready tables (includes dbt_payments task group)

### Data Storage

Open the GCP Console and explore these buckets:

- `calitp-payments-littlepay-raw-v3` - Raw Littlepay data files
- `calitp-payments-littlepay-parsed-v3` - Parsed Littlepay JSONL files
- `calitp-enghouse-raw` - Raw Enghouse data files
- `calitp-elavon-raw` - Raw Elavon data files
- `calitp-elavon-parsed` - Parsed Elavon JSONL files

### Data Warehouse

In BigQuery, explore these datasets:

- `external_littlepay_v3` - External tables for Littlepay data
- `external_enghouse` - External tables for Enghouse data
- `external_elavon` - External tables for Elavon data
- `staging` - Staging models for all data sources (light transformations)
- `mart_payments` - Final analytics-ready tables (for all vendors), including reliability tables for data quality monitoring

### Visualization

Access Metabase (link in your onboarding docs) and find:

- Agency-specific collections (e.g., "Payments Collection - MST")
- Dashboards showing transaction metrics, revenue, ridership

## Step 2: Follow a Transaction Through the System

Let's trace how a single tap becomes a dashboard metric. This example follows a Littlepay agency (MST), but the overall flow is similar for Enghouse agencies (though Enghouse data is delivered directly to GCS without a sync DAG, and with a different table schema).

### 2.1 Raw Data Arrives

A rider taps their card on an MST bus. Within minutes:

- Littlepay receives the tap event
- Littlepay publishes data in daily batches to their S3 bucket, written across multiple table types (device_transactions, micropayments, settlements, etc.)

### 2.2 Sync DAG Runs

Every hour, the `sync_littlepay_v3` DAG runs:

```
1. Connects to Littlepay's S3 using agency-specific AWS credentials
2. Downloads new files to our GCS bucket `calitp-payments-littlepay-raw-v3`
3. Partitions by timestamp and agency
```

Check the DAG in Airflow:

- Go to Airflow UI → DAGs → sync_littlepay_v3
- Verify the latest run succeeded for MST

### 2.3 Parse DAG Runs

Shortly after, the `parse_littlepay_v3` DAG runs:

```
1. Reads raw files from `calitp-payments-littlepay-raw-v3`
2. Converts to gzipped JSONL format
3. Writes to `calitp-payments-littlepay-parsed-v3`
```

### 2.4 External Tables (One-Time Setup)

BigQuery external tables have already been created and point to the GCS buckets:

```
- External tables are defined once and don't need to be recreated
- They automatically reflect new files added to GCS
- The create_external_tables DAG only runs when schema changes
```

**Note:** New data appears in external tables automatically as soon as files land in GCS - no DAG run needed!

### 2.5 dbt Transformations Run

The `dbt_daily` DAG runs dbt models (specifically the `dbt_payments` task group):

```
1. Staging models clean and standardize data
2. Intermediate models join and enrich data
3. Mart models create final analytics tables
```

The tap now appears in `mart_payments.fct_payments_rides_v2`!

### 2.6 Metabase Displays the Data

Agencies view their dashboard:

```
1. Metabase connects using agency-specific service account
2. Row-level security ensures they only see their data
3. Dashboard queries `fct_payments_rides_v2` or other mart table as appropriate
4. Metrics update with the new transaction
```

## Step 3: Verify the System is Working

Let's check that everything is healthy:

### 3.1 Check Airflow DAGs

In Airflow UI:

- [ ] All payment-related DAGs show green (success) for latest runs
- [ ] No DAGs are paused that should be running
- [ ] Recent runs completed within expected timeframes

### 3.2 Check BigQuery Data Freshness

Run this query in BigQuery:

```sql
SELECT 
  participant_id,
  MAX(transaction_date_time_pacific) as latest_transaction,
  DATETIME_DIFF(CURRENT_DATETIME(), MAX(transaction_date_time_pacific), HOUR) as hours_since_latest
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
GROUP BY participant_id
ORDER BY latest_transaction DESC
```

You should see recent transactions for active agencies. Smaller agencies may not have frequent transactions, so delayed transactions may not necessarily represent data quality issues.

### 3.3 Check Metabase Dashboards

Pick an active agency (e.g., MST):

- [ ] Dashboard loads without errors
- [ ] Data appears current (check date filters)
- [ ] Visualizations render correctly
- [ ] No "permission denied" errors

## Step 4: Explore Key Resources

Bookmark these resources:

### Documentation

- [Payments Documentation Home](../README.md)
- [Littlepay Official Docs](https://docs.littlepay.io/data/) (credentials for new users need to be generated by Littlepay)
- [Main Data Infra Docs](https://docs.calitp.org/data-infra/)

### Code Repositories

- [data-infra GitHub](https://github.com/cal-itp/data-infra)
- Airflow DAGs: `airflow/dags/sync_littlepay_v3/`, `airflow/dags/parse_littlepay_v3/`, etc.
- dbt models:
  - `warehouse/models/staging/payments/`
  - `warehouse/models/intermediate/payments/`
  - `warehouse/models/mart/payments/`

### GCP Resources

- [Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra) - AWS keys, credentials
- [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=cal-itp-data-infra) - Agency-specific accounts (managed via Terraform)
- GCP User Groups - Cal-ITP team members should be added to the `DOT_DDS_Data_Pipeline_and_Warehouse_Users` GCP group
- [BigQuery](https://console.cloud.google.com/bigquery?project=cal-itp-data-infra) - Data warehouse

### Monitoring

- Airflow UI - DAG status and logs
- [GCP Logs Explorer](https://console.cloud.google.com/logs) - Detailed logs
- Metabase - Data quality checks

## What You've Learned

Congratulations! You now understand:

- ✅ The purpose of the payments data ecosystem
- ✅ The key vendors (Littlepay, Enghouse, and Elavon)
- ✅ How data flows through the pipeline
- ✅ Where data is stored at each stage
- ✅ How to verify the system is working
- ✅ Where to find important resources

## Next Steps

Now that you understand the basics:

1. **Learn the data flow in detail**: Continue to [Understanding the Data Flow](02-understanding-data-flow.md)
2. **Try onboarding an agency**: Work through [Your First Agency Onboarding](03-first-agency-onboarding.md)
3. **Explore the how-to guides**: Check out the [How-To Guides](../how-to/) for specific tasks

## Common Questions

**Q: How often does data update?**\
A: Sync DAGs run hourly for Littlepay, Enghouse data is delivered directly to GCS daily, Elavon data syncs daily, and dbt transformations run daily. For dats feeds that also have parse tasks (currently Littlepay and Elavon), data will not update until they also run.

**Q: Why do we have both fare collection data (Littlepay/Enghouse) and payment processor data (Elavon)?**\
A: Fare collection vendors handle tap events and fare calculation; Elavon handles actual payment processing. We need both for complete visibility into the payments data ecosystem.

**Q: What's the difference between Littlepay and Enghouse?**\
A: Both are fare collection processors, but agencies contract with one or the other. They have different data schemas and delivery mechanisms (Littlepay uses S3, Enghouse uses SFTP, Elavon uses SFTP).

**Q: Can I query the data directly?**\
A: Yes! Use BigQuery to query `mart_payments` tables. Be aware of row-level security - you may need to be added to the `DOT_DDS_Data_Pipeline_and_Warehouse_Users` GCP group.

**Q: What if I see errors in Airflow?**\
A: Check the [Troubleshoot Data Sync Issues](../how-to/troubleshoot-sync-issues.md) guide.

## Feedback

Found something unclear? Have suggestions? Please update this documentation or reach out to the data engineering team.

______________________________________________________________________

**Next Tutorial:** [Understanding the Data Flow →](02-understanding-data-flow.md)
