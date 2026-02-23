# Understanding the Data Flow

**Tutorial Duration:** ~45 minutes\
**Prerequisites:** [Getting Started with the Payments Ecosystem](01-getting-started.md)\
**What You'll Learn:** Deep dive into how data moves through the payments pipeline

## Introduction

In this tutorial, you'll gain a detailed understanding of how payments data flows from vendors through our pipeline to analytics tables. We'll follow actual data files, examine transformations, and understand the purpose of each step.

## The Complete Data Journey

```mermaid
graph TB
    A[Rider Taps Card] --> B[Littlepay Validator]
    A --> B2[Enghouse Validator]
    B --> C[Littlepay S3 Bucket]
    B2 --> C2[Enghouse Direct to GCS]
    D[Payment Processed\ (Received from Littlepay or Elavon)] --> E[Elavon SFTP Server]
    
    C --> F[sync_littlepay_v3 DAG]
    C2 --> H2[GCS: calitp-enghouse-raw]
    E --> G[sync_elavon DAG]
    
    F --> H[GCS: calitp-payments-littlepay-raw-v3]
    G --> I[GCS: calitp-elavon-raw]
    
    H --> J[parse_littlepay_v3 DAG]
    H2 --> J2[No parse needed]
    I --> K[parse_elavon DAG]
    
    J --> L[GCS: calitp-payments-littlepay-parsed-v3]
    J2 --> L2[Data already in GCS]
    K --> M[GCS: calitp-elavon-parsed]
    
    L --> N[create_external_tables DAG]
    L2 --> N
    M --> N
    
    N --> O[BigQuery External Tables]
    O --> P[dbt Staging Models]
    P --> Q[dbt Intermediate Models]
    Q --> R[dbt Mart Models]
    R --> S[Metabase Dashboards]
```

## Part 1: Vendor Data Sources

### Littlepay Data Structure

Littlepay provides data through their AWS S3 buckets, with one bucket per agency (called an `instance` or `participant_id` in the configs and data).

**Key Tables Provided:**

- `authorisations` - Authorisations represent the communication with the acquirer that is not a settlement
- `customer-funding-sources` - Customer funding sources are cards (physical or digital) which are stored for payment processing
- `device-transactions` - Device transactions represent a 'tap' of a customer identifier, such as a credit card or phone, on a physical device
- `device-transaction-purchases` - Device transaction purchases represent purchase data related to the tap completed by the customer's purchase
- `micropayments` - A micropayment represents a debit or credit that is made against the customer's funding source for a trip
- `micropayment-adjustments` - A micropayment adjustment represents a micropayment that is either eligible or has qualified to be adjusted by a product
- `micropayment-device-transactions` - Micropayment device transactions is the link between micropayments and device-transactions which can be one or multiple
- `products` - Fare products (day passes, fare caps, etc.)
- `refunds` - Refunds may be requested by a merchant customer for a given debit micropayment; for example, providing a refund for a trip
- `settlements` - A settlement represents the amount of money to be cleared by the acquirer from the customers funding source
- `terminal-device-transactions` - Terminal device transactions represent the information received from the devices, each row of data represents a communication with the device

**File Format (Littlepay S3):**

```
eldorado-transit/v3/terminal-device-transactions/202601111103_terminaldevicetransactions.psv
```

**File Format (Our GCS Raw):**

```
gs://calitp-payments-littlepay-raw-v3/device-transactions/
  instance=eldorado-transit/
    filename=202601281105_devicetransactions.psv/
      ts=2026-01-28T12:01:47.458556+00:00/
        202601281105_devicetransactions.psv
```

**File Format (Our GCS Parsed):**

```
gs://calitp-payments-littlepay-parsed-v3/device-transactions/
  instance=eldorado-transit/
    extract_filename=202601281105_devicetransactions.psv/
      ts=2026-01-28T12:01:47.458556+00:00/
        202601281105_devicetransactions.jsonl.gz
```

Raw files are pipe-separated (.psv). Parsed files are converted to gzipped JSONL format, partitioned by instance, extract_filename, and sync timestamp.

### Enghouse Data Structure

Enghouse provides data directly to our GCS buckets via SFTP server (no intermediate vendor buckets to copy from).

**Key Tables Provided:**

- `taps` - These are individual “transactions” made by the passenger, meaning each tap of a card on the terminal. Each token (card) can have one or more taps on a given day. (Similar to Littlepay's device-transactions)
- `transactions` - These are authorization operations that are to the Acquirer in connection with each card (similar to Littlepay's micropayments)
- `pay_windows` - payment windows that open with the first tap and close at midnight, one payment window can contain multiple taps, each token (card) has only one payment window per day
- `ticket_results` - Ticket/fare product results

**File Format (Enghouse GCS Raw):**

```
gs://cal-itp-data-infra-enghouse-raw/tap/ventura/VENTURA_TAPtaps-2026-01-28.csv
```

Data is delivered directly to GCS by Enghouse as CSV files. The schema differs significantly from Littlepay.

### Elavon Data Structure

Elavon provides data through an SFTP server with a single shared directory for all agencies.

**Data Provided:**

- Single file containing all transaction types, differentiated by `batch_type`:
  - 'A' = Adjustment transactions
  - 'B' = Billing transactions
  - 'C' = Chargeback transactions
  - 'D' = Deposit transactions

**File Format (Elavon Raw):**

```
gs://calitp-elavon-raw/ts=2026-01-28T00:00:33.636202+00:00/010PR001618FUND20260127.zip
```

**File Format (Elavon Parsed):**

```
gs://calitp-elavon-parsed/transactions/
  dt=2026-01-28/
    execution_ts=2026-01-28T02:33:15.654837+00:00/
      transactions.jsonl.gz
```

Files are pipe-separated text files inside zip archives, with all agencies' data mixed together. After parsing, they're separated by date and converted to JSONL. The different transaction types are separated downstream into transaction-specific files in the warehouse using the `batch_type` field.

## Part 2: Sync Stage - Raw Data Ingestion

**Note:** Enghouse data is delivered directly to our GCS buckets (`gs://calitp-enghouse-raw/`), so there is no sync DAG for Enghouse. The data appears directly in GCS and proceeds to the external tables stage.

### Littlepay Sync Process

**DAG:** `sync_littlepay_v3`\
**Schedule:** Hourly at :00 (`0 * * * *`)\
**Code:** `airflow/dags/sync_littlepay_v3/`

#### What Happens:

1. **Configuration Loading**

   - Each agency has a YAML config file (e.g., `mst.yml`)
   - Config specifies: instance, AWS credentials secret name, source bucket

2. **AWS Connection**

   - Retrieves AWS access key from Secret Manager
   - Connects to agency-specific S3 bucket
   - Uses boto3 to list and download files

3. **File Download**

   - Downloads all PSV files from S3
   - Preserves directory structure
   - Uploads to GCS with partitioning by instance, filename, and timestamp

4. **Partitioning**

   - Partitions by instance, filename, and sync timestamp (structurally efficient)
   - Allows tracking when data was synced
   - Enables historical replay if needed

**Example File Path:**

```
gs://calitp-payments-littlepay-raw-v3/device-transactions/
  instance=eldorado-transit/
    filename=202601281105_devicetransactions.psv/
      ts=2026-01-28T12:01:47.458556+00:00/
        202601281105_devicetransactions.psv
```

### Elavon Sync Process

**DAG:** `sync_elavon`\
**Schedule:** Daily at midnight (`0 0 * * *`)\
**Code:** `airflow/dags/sync_elavon/`

#### What Happens:

1. **SFTP Connection**

   - Connects using credentials from Secret Manager
   - Lists all files in `/data` directory

2. **Mirror Download**

   - Downloads entire directory contents
   - Preserves original file names and structure
   - Uploads to GCS with timestamp partition

3. **Full Snapshot**

   - Each run creates a complete snapshot
   - Allows point-in-time recovery
   - Files remain zipped at this stage
   - We should explore making this more efficient (not downloading entire history) in future

**Example File Path:**

```
gs://calitp-elavon-raw/ts=2026-01-28T00:00:33.636202+00:00/010PR001618FUND20260127.zip
```

## Part 3: Parse Stage - Format Conversion

### Why Parse?

BigQuery external tables work best with:

- JSONL (JSON Lines) format
- Gzipped compression
- Valid column names (no special characters)
- Consistent data types

Parsing converts vendor formats to BigQuery-compatible formats with minimal transformation.

### Littlepay Parse Process

**DAG:** `parse_littlepay_v3`\
**Schedule:** Hourly at :30 (`30 * * * *`) - runs 30 minutes after sync\
**Code:** `airflow/dags/parse_littlepay_v3/`

#### What Happens:

1. **Read Raw CSV**

   - Reads CSV from `calitp-payments-littlepay-raw-v3`
   - Uses pandas for parsing

2. **Minimal Transformations**

   - Rename columns with invalid characters (e.g., `transaction-id` → `transaction_id`)
   - Convert date strings to ISO format
   - Handle null values consistently
   - **No business logic changes**

3. **Write JSONL**

   - Convert each row to JSON object
   - Write one JSON object per line
   - Gzip the output
   - Upload to `gs://calitp-payments-littlepay-parsed-v3/`

**Example Transformation:**

CSV Input:

```psv
littlepay_transaction_id|transaction_time|participant_id|charge_amount
abc123|2024-01-15 10:30:00|mst,2.50
```

JSONL Output (gzipped):

```jsonl
{"littlepay_transaction_id":"abc123","transaction_time":"2024-01-15T10:30:00","participant_id":"mst","charge_amount":2.50}
```

### Elavon Parse Process

**DAG:** `parse_elavon`\
**Schedule:** Daily at 2:00 AM (`0 2 * * *`) - runs 2 hours after sync\
**Code:** `airflow/dags/parse_elavon/`

#### What Happens:

1. **Unzip Files**

   - Extracts pipe-separated text files from zips

2. **Parse Pipe-Separated Format**

   - Reads files with `|` delimiter
   - Handles quoted fields
   - Manages encoding issues

3. **Filter by Agency**

   - Identifies agency using `customer_name` field
   - Separates mixed data into agency-specific files

4. **Write JSONL**

   - Converts to JSONL format
   - Gzips output
   - Uploads to `gs://calitp-elavon-parsed/`

## Part 4: External Tables - Making Data Queryable\*

**DAG:** `create_external_tables`\
**Schedule:** Hourly\
**Code:** `airflow/dags/create_external_tables/`

**\*Note:** This DAG only needs to run when table schemas change or new tables are added. It doesn't need to run for new data to appear - external tables automatically reflect new files in GCS.

### What Happens:

1. **Define Table Schema**

   - Defines BigQuery external table schemas
   - Points to GCS file locations using patterns
   - Specifies column names and types
   - Sets up partitioning
   - Uses appropriate format (JSONL for Littlepay/Elavon, CSV for Enghouse)

2. **Create/Update External Tables**

   - Creates or updates BigQuery external table definitions
   - **Does not scan or process the actual data**
   - Just defines how BigQuery should read files from GCS

3. **Result**

   - Data is queryable in BigQuery
   - No data is copied (external tables read directly from GCS)
   - New files automatically appear in queries without re-running this DAG
   - Tables appear in `external_littlepay_v3`, `external_elavon`, and `external_enghouse` datasets

## Part 5: dbt Transformations - Business Logic

**DAG:** `dbt_daily`\
**Schedule:** Daily\
**Code:** `warehouse/models/`

### Staging Layer

**Location:** `warehouse/models/staging/payments/`\
**Purpose:** Light cleaning and standardization

**Example: `stg_littlepay__device_transactions_v3`**

- Casts data types correctly
- Renames columns to standard naming conventions
- Adds surrogate keys
- Filters out test data, duplicates
- **Still one row per source row**

```sql
SELECT
  littlepay_transaction_id,
  transaction_date_time_pacific,
  participant_id,
  -- ... more columns
FROM `cal-itp-data-infra.staging.stg_littlepay__device_transactions_v3`
```

### Intermediate Layer

**Location:** `warehouse/models/intermediate/payments/`\
**Purpose:** Joins, enrichments, complex logic

**Example: `int_payments__micropayments_adjustments_refunds_joined`**

- Joins micropayments with adjustments and refunds
- Combines related payment data
- Prepares data for final mart models

**Special Note: Littlepay Feed Version Union Tables**

A unique aspect of the Littlepay pipeline is handling the migration from older feed versions to v3. Some agencies started on Littlepay's older feed versions (v1/v2) and migrated to v3, while newer agencies started directly on v3. Feeds v1/v2 have been deprecated and are no longer provided. All agencies now use feed v3, with prior data from prior feed versions unioned (as relevant).

The intermediate layer includes union tables that combine historical v1 data with current v3 data:

- `int_littlepay__unioned_micropayments` - Unions v1 and v3 micropayments
- `int_littlepay__unioned_device_transactions` - Unions v1 and v3 device transactions
- `int_littlepay__unioned_settlements` - Unions v1 and v3 settlements
- And similar for other Littlepay tables

These union tables handle the cutover date logic (May 2025), using v1/v2 data before migration and v3 data after, providing a seamless view of historical and current data for agencies that migrated.

### Mart Layer

**Location:** `warehouse/models/mart/payments/`\
**Purpose:** Final analytics-ready tables

**Key Mart Models:**

1. **`fct_payments_rides_v2`** - The main Littlepay rides fact table

   - One row per completed trip
   - Joins Littlepay micropayments with device transactions
   - Adds route, stop, and geographic information
   - Includes fare calculations and adjustments
   - **This is what Metabase dashboards query for Littlepay agencies**

2. **`fct_payments_rides_enghouse`** - The main Enghouse rides fact table

   - One row per completed trip
   - Enghouse tap and transaction data
   - **This is what Metabase dashboards query for Enghouse agencies**

3. **`fct_payments_aggregations`** - Settlement groupings

   - One row per aggregation (group of micropayments)
   - Used for financial reconciliation

4. **`fct_elavon__transactions`** - Payment processor transactions

   - One row per card transaction
   - Used for settlement verification

### Row-Level Security

Applied in mart models via post-hook:

```sql
{{ config(materialized = 'table',
    post_hook="{{ payments_littlepay_row_access_policy() }}") }}
```

This ensures agencies only see their own data when querying through their service account. You can find the dbt macros that power these policies in `warehouse/macros/create_row_access_policy.sql`.

## Part 6: Metabase Visualization

### Connection Setup

Each agency has:

- Dedicated service account (e.g., `mst-payments-user@cal-itp-data-infra.iam.gserviceaccount.com`)
- Metabase "Database" connection using that service account
- Row-level security grants access based on:
  - `participant_id` for Littlepay agencies
  - `operator_id` for Enghouse agencies
  - `organization_name` for Elavon data

### Dashboard Queries

The questions that comprise the dashboards query various tables in `mart_payments`, including:

- `fct_payments_rides_v2` (Littlepay rides)
- `fct_payments_rides_enghouse` (Enghouse rides)
- `fct_payments_settlements` (settlement data)
- More

Row-level security automatically filters queries to these tables to only the agency's data.

## Part 7: Hands-On Exercise

Let's trace a specific transaction through the entire pipeline! This exercise uses a Littlepay agency (MST) as an example, but the process is similar for Enghouse agencies (with different table and column names).

### Step 1: Find a Recent Transaction

In BigQuery, run:

```sql
SELECT 
  littlepay_transaction_id,
  participant_id,
  transaction_date_time_pacific,
  charge_amount
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id = 'mst'
ORDER BY transaction_date_time_pacific DESC
LIMIT 1
```

Note the `littlepay_transaction_id` (e.g., `abc123xyz`).

### Step 2: Find in Staging

```sql
SELECT *
FROM `cal-itp-data-infra.staging.stg_littlepay__device_transactions_v3`
WHERE littlepay_transaction_id = 'abc123xyz'
```

Compare columns - notice the staging model has more raw fields.

### Step 3: Find in External Table

```sql
SELECT *
FROM `cal-itp-data-infra.external_littlepay_v3.device_transactions`
WHERE littlepay_transaction_id = 'abc123xyz'
```

This queries the JSONL file directly from GCS.

### Step 4: Find the Raw File

In GCS Console:

1. Navigate to `calitp-payments-littlepay-parsed-v3`
2. Browse to `mst/device_transactions/`
3. Find the date partition matching your transaction
4. Download and examine the JSONL.gz file

### Step 5: Check Airflow Logs

In Airflow:

1. Go to `sync_littlepay_v3` DAG
2. Find the run that would have synced this transaction
3. Check logs to see the file being downloaded

## What You've Learned

You now understand:

- ✅ How vendor data is structured and accessed (Littlepay, Enghouse, Elavon)
- ✅ The sync process for Littlepay and Elavon (and why Enghouse doesn't need one)
- ✅ Why and how we parse data
- ✅ How external tables make data queryable
- ✅ The dbt transformation layers (staging, intermediate, mart)
- ✅ How row-level security works
- ✅ How Metabase connects and queries data
- ✅ How to trace a transaction through the entire pipeline

## Next Steps

1. **Practice onboarding**: Try [Your First Agency Onboarding](03-first-agency-onboarding.md)
2. **Learn about security**: See [Update Row Access Policies](../how-to/update-row-access-policies.md) for how row-level security is implemented
3. **Explore the code**: Check out the dbt models in `warehouse/models/mart/payments/` in the GitHub repository

## Common Questions

**Q: Why not load data directly into BigQuery tables?**\
A: External tables preserve the raw data in GCS, allowing us to replay transformations without re-syncing from vendors. It also separates storage from compute.

**Q: Why do we need both sync and parse DAGs?**\
A: Sync preserves the exact vendor format. Parse converts to BigQuery-compatible format. This separation allows us to re-parse without re-syncing.

**Q: How long does data take to appear in dashboards?**\
A: Data for all vendors should appear within 24 hours. Exact timing depends on when the data was published by a vendor, and the particular schedules for the sync/parse/and transform tasks.

**Q: What if a file is corrupted?**\
A: We can re-run the parse DAG for that specific partition without re-syncing from the vendor.

______________________________________________________________________

**Previous:** [← Getting Started](01-getting-started.md) | **Next:** [Your First Agency Onboarding →](03-first-agency-onboarding.md)
