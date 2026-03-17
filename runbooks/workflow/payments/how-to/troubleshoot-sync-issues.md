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

**Symptom:** Latest data is days old

**Diagnostic steps:**

1. Check when sync DAGs last ran successfully
2. Verify parse DAGs ran after sync
3. Check dbt transformation schedule
4. Look for failed DAG runs

### Sync DAG Failing

**Symptom:** Airflow shows red/failed DAG runs

**Diagnostic steps:**

1. Check Airflow logs for error messages
2. Verify credentials are valid
3. Check vendor data source is accessible
4. Look for configuration errors

## Understanding Sync Behavior

Both Littlepay and Elavon sync DAGs are **"now" type DAGs** - they sync whatever is currently available in the source, not based on time windows.

**Littlepay sync:**

- Lists ALL files in the agency's S3 bucket
- Compares each file against what's already in GCS (by LastModified date and ETag)
- Only copies files that are new or have been updated
- **Result:** Missing a sync run doesn't lose data - the next run will catch up

**Elavon sync:**

- Mirrors the entire contents of the SFTP `/data` directory
- Creates a timestamped snapshot of everything available
- **Result:** Missing a sync run doesn't lose data - the next run gets everything

**Parse DAGs:**

- Process whatever is in the raw GCS buckets
- Idempotent - can be safely rerun without creating duplicates

### Common Misconceptions

**❌ "If I rerun, I'll get duplicate data"**

- ✅ False - sync logic checks for existing files, parse creates new partitions, dbt deduplicates

**❌ "If a sync fails, that data is lost forever"**

- ✅ False - next run will sync all available files from the source

**❌ "I need to manually backfill missed hours/days"**

- ✅ False - "now" type DAGs sync whatever is currently available, not time-based windows

**❌ "Parse must run immediately after sync"**

- ✅ False - parse can run anytime after sync; it processes whatever is in raw GCS

## Related Documentation

- [Onboard a New Littlepay Agency](onboard-littlepay-agency.md)
- [Onboard a New Enghouse Agency](onboard-enghouse-agency.md)
- [Onboard a New Elavon Agency](onboard-elavon-agency.md)
- [Rotate Littlepay AWS Keys](rotate-littlepay-keys.md)
- [Update Row Access Policies](update-row-access-policies.md)

______________________________________________________________________

**Remember:** Most issues are configuration or timing related. Check the basics first (credentials, paths, schedules) before diving deep.
