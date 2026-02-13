# Troubleshoot Data Sync Issues

**Task:** Diagnose and fix problems with payments data syncing\
**Time Required:** 30 minutes - 2 hours (depending on issue)\
**Prerequisites:** Access to Airflow, GCP, BigQuery

## Overview

This guide helps you troubleshoot common issues with the payments data pipeline, from vendor data sync through to BigQuery tables. Use this when data isn't flowing as expected.

## Quick Diagnostic Checklist

Start here to quickly identify where the problem is:

- [ ] **Airflow DAGs running?** Check DAG status in Airflow UI
- [ ] **Raw data in GCS?** Verify files exist in raw buckets
- [ ] **Parsed data in GCS?** Check parsed buckets
- [ ] **External tables working?** Query external tables in BigQuery
- [ ] **dbt models built?** Check mart tables have recent data
- [ ] **Row access working?** Test with service account

## Common Issues by Symptom

### No Data in Dashboards

**Symptom:** Metabase dashboard shows no data or "No results"

**Diagnostic steps:**

1. Check if data exists in BigQuery mart tables
2. Verify row access policy grants access
3. Check dashboard date filter range
4. Confirm Metabase database connection

**See:** [No Data in Mart Tables](#no-data-in-mart-tables)

### Data is Stale

**Symptom:** Latest data is hours or days old

**Diagnostic steps:**

1. Check when sync DAGs last ran successfully
2. Verify parse DAGs ran after sync
3. Check dbt transformation schedule
4. Look for failed DAG runs

**See:** [Sync DAG Not Running](#sync-dag-not-running)

### Sync DAG Failing

**Symptom:** Airflow shows red/failed DAG runs

**Diagnostic steps:**

1. Check Airflow logs for error messages
2. Verify credentials are valid
3. Check vendor data source is accessible
4. Look for configuration errors

**See:** [Littlepay Sync Failures](#littlepay-sync-failures), [Elavon Sync Failures](#elavon-sync-failures)

## Littlepay Sync Issues

### Littlepay Sync Failures

**DAG:** `sync_littlepay_v3`

#### AWS Access Denied

**Error message:** `AccessDenied`, `InvalidAccessKeyId`, `SignatureDoesNotMatch`

**Solutions:**

1. Verify AWS credentials in Secret Manager:

   ```bash
   gcloud secrets versions access latest \
     --secret=LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY \
     --project=cal-itp-data-infra
   ```

2. Test credentials locally:

   ```bash
   aws s3 ls s3://littlepay-<merchant-id>/ --profile <merchant-id>
   ```

3. Check if keys need rotation (>90 days old)

4. Verify secret name in YAML config matches Secret Manager

**Related:** [Rotate Littlepay AWS Keys](rotate-littlepay-keys.md)

#### S3 Bucket Not Found

**Error message:** `NoSuchBucket`, `404 Not Found`

**Solutions:**

1. Verify bucket name in sync config YAML
2. Check with Littlepay that bucket exists
3. Confirm AWS credentials have access to correct bucket

#### No New Files

**Symptom:** DAG succeeds but no new files synced

**Solutions:**

1. Check if Littlepay is actually generating new data

2. Verify date partitions in S3:

   ```bash
   aws s3 ls s3://littlepay-<merchant-id>/device_transactions/ --profile <merchant-id>
   ```

3. Check sync DAG logs for "0 files synced" messages

4. Confirm agency has active transactions

### Littlepay Parse Failures

**DAG:** `parse_littlepay_v3`

#### CSV Parsing Errors

**Error message:** `ParserError`, `ValueError`, encoding errors

**Solutions:**

1. Check raw CSV file format in GCS
2. Verify CSV has expected columns
3. Look for malformed data (extra commas, quotes)
4. Check for encoding issues (UTF-8 expected)

#### Schema Mismatch

**Error message:** Column not found, unexpected columns

**Solutions:**

1. Compare CSV headers with expected schema
2. Check if Littlepay changed their schema
3. Update parsing code if schema changed
4. Verify using correct Littlepay feed version (v3)

## Enghouse Sync Issues

### No Enghouse Sync DAG

**Current Implementation:** Enghouse delivers data directly to GCS via SFTP on a daily basis. There is no Airflow sync DAG for Enghouse (unlike Littlepay).

**Expected Behavior:**

- Data appears in `gs://calitp-enghouse-raw/` daily
- No sync DAG runs are needed
- External tables read directly from raw GCS files

**Future Consideration:** A parse DAG similar to Littlepay's may be added in the future to standardize data processing.

**Diagnostic steps if data is missing:**

1. Check GCS bucket for new files:

   ```bash
   gsutil ls -l gs://calitp-enghouse-raw/tap/ | tail -10
   gsutil ls -l gs://calitp-enghouse-raw/tx/ | tail -10
   ```

2. Verify file timestamps are recent (within last 24 hours)

3. Contact Enghouse if no new files are appearing

4. Check with team if SFTP delivery configuration changed

### Enghouse Data Missing

**Symptom:** No data in Enghouse tables

**Solutions:**

1. Verify files exist in GCS raw bucket
2. Check external table definitions point to correct paths
3. Confirm operator_id in data matches expectations
4. Check with Enghouse vendor on data delivery

## Elavon Sync Issues

### Elavon Sync Failures

**DAG:** `sync_elavon`

#### SFTP Connection Failed

**Error message:** `Connection refused`, `Authentication failed`, `Timeout`

**Solutions:**

1. Verify SFTP credentials in Secret Manager
2. Check network connectivity to Elavon SFTP server
3. Confirm SFTP server is operational (contact Elavon)
4. Check firewall rules allow SFTP connection

#### No New Files on SFTP

**Symptom:** DAG succeeds but mirrors empty directory

**Solutions:**

1. Manually connect to SFTP and list files
2. Verify Elavon is uploading new files
3. Check SFTP directory path in sync configuration
4. Confirm all agencies' data is in shared feed

### Elavon Parse Failures

**DAG:** `parse_elavon`

#### Pipe-Separated Parsing Errors

**Error message:** Delimiter errors, field count mismatch

**Solutions:**

1. Check raw file format (should be pipe-separated)
2. Verify files are properly unzipped
3. Look for malformed records
4. Check for encoding issues

## External Table Issues

### External Table Returns No Data

**Symptom:** Query returns 0 rows but files exist in GCS

**Solutions:**

1. Verify external table definition:

   ```sql
   SELECT * FROM `cal-itp-data-infra.INFORMATION_SCHEMA.TABLES`
   WHERE table_name = '<table_name>';
   ```

2. Check GCS URI pattern matches actual file locations

3. Verify file format (JSONL, CSV, etc.) matches table definition

4. Check for schema mismatches

5. Try querying with explicit file path:

   ```sql
   SELECT * FROM `gs://bucket/path/to/file.jsonl.gz`
   ```

### External Table Schema Errors

**Error message:** Schema mismatch, column not found

**Solutions:**

1. Check if vendor changed their schema
2. Verify external table schema definition
3. Update external table if needed
4. Check for data type mismatches

## dbt Transformation Issues

### No Data in Mart Tables

**Symptom:** External/staging tables have data but mart tables don't

**Solutions:**

1. Check if dbt DAG ran successfully:

   - Navigate to `transform_warehouse` DAG in Airflow
   - Check logs for errors

2. Verify dbt models compiled:

   ```bash
   # In warehouse directory
   dbt compile --select mart_payments.*
   ```

3. Check for dbt test failures

4. Look for filtering logic that might exclude data

5. Verify entity mapping exists for agency

### dbt Model Failures

**Error message:** SQL compilation errors, runtime errors

**Solutions:**

1. Check dbt logs in Airflow

2. Run dbt locally to debug:

   ```bash
   cd warehouse
   dbt run --select <model_name>
   ```

3. Check for:

   - Missing dependencies
   - SQL syntax errors
   - Schema changes
   - Data quality issues

### Row Access Policy Not Applied

**Symptom:** Agencies can see other agencies' data

**Solutions:**

1. Verify policy macro was updated
2. Check dbt models rebuilt after policy change
3. Confirm policy syntax is correct
4. Test with service account credentials

**Related:** [Update Row Access Policies](update-row-access-policies.md)

## Data Quality Issues

### Missing Transactions

**Symptom:** Transaction count lower than expected

**Diagnostic queries:**

```sql
-- Check transaction counts by day
SELECT 
  DATE(transaction_time) as date,
  COUNT(*) as transactions
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id = '<participant-id>'
GROUP BY date
ORDER BY date DESC
LIMIT 30;

-- Compare external vs mart
SELECT 
  'external' as source,
  COUNT(*) as count
FROM `cal-itp-data-infra.external_littlepay.device_transactions`
WHERE participant_id = '<participant-id>'
UNION ALL
SELECT 
  'mart' as source,
  COUNT(*) as count
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id = '<participant-id>';
```

**Solutions:**

1. Check for filtering in dbt models
2. Verify all source files were synced
3. Look for data quality test failures
4. Check for incomplete trips (tap on without tap off)

### Duplicate Transactions

**Symptom:** Same transaction appears multiple times

**Diagnostic query:**

```sql
SELECT 
  littlepay_transaction_id,
  COUNT(*) as occurrences
FROM `cal-itp-data-infra.mart_payments.fct_payments_rides_v2`
WHERE participant_id = '<participant-id>'
GROUP BY littlepay_transaction_id
HAVING COUNT(*) > 1;
```

**Solutions:**

1. Check for duplicate source files
2. Verify deduplication logic in dbt models
3. Look for sync DAG running multiple times
4. Check partition logic

## Monitoring and Prevention

### Set Up Alerts

Monitor these metrics:

- DAG failure rate
- Data freshness (time since last update)
- Row counts (sudden drops)
- Sync duration (unusual increases)

### Regular Checks

Weekly:

- [ ] Review failed DAG runs
- [ ] Check data freshness for all agencies
- [ ] Verify row counts are reasonable
- [ ] Test random sample of dashboards

Monthly:

- [ ] Review AWS key expiration dates
- [ ] Check GCS bucket sizes
- [ ] Audit row access policies
- [ ] Review error logs for patterns

## Getting Help

### Information to Gather

Before asking for help, collect:

1. Agency name and identifier
2. Error messages (full text)
3. DAG run ID and timestamp
4. Steps you've already tried
5. Screenshots if relevant

### Where to Look

- **Airflow logs:** Most detailed error information
- **GCP Logs Explorer:** System-level logs
- **BigQuery job history:** Query execution details
- **GitHub issues:** Known problems and solutions

### Escalation

If you can't resolve:

1. Document the issue thoroughly
2. Check if it affects multiple agencies
3. Determine urgency (data loss vs. delay)
4. Contact data infrastructure team
5. Create incident ticket if needed

## Common Error Messages

### "No such file or directory"

- Check GCS paths
- Verify files were synced
- Check partition dates

### "Permission denied"

- Verify service account permissions
- Check row access policies
- Confirm IAM roles

### "Table not found"

- Check table name spelling
- Verify dataset exists
- Confirm dbt models ran

## Related Documentation

- [Onboard a New Littlepay Agency](onboard-littlepay-agency.md)
- [Onboard a New Enghouse Agency](onboard-enghouse-agency.md)
- [Onboard a New Elavon Agency](onboard-elavon-agency.md)
- [Rotate Littlepay AWS Keys](rotate-littlepay-keys.md)
- [Update Row Access Policies](update-row-access-policies.md)

______________________________________________________________________

**Remember:** Most issues are configuration or timing related. Check the basics first (credentials, paths, schedules) before diving deep.
