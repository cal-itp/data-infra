# Metabase

[Metabase](https://www.metabase.com/) is the BI / dashboarding tool Cal-ITP runs
on Cloud Run, backed by a Cloud SQL Postgres instance (its application metadata:
dashboards, questions, collections, users, permissions). The analytics data the
dashboards query lives in BigQuery, not in this database.

The service is deployed via Terraform in `iac/`:

- Staging: `iac/cal-itp-data-infra-staging/metabase/us/`
- Production: `iac/cal-itp-data-infra/metabase/us/`

This directory holds the container build for the service:

- [`Dockerfile.production`](./Dockerfile.production) / [`Dockerfile.staging`](./Dockerfile.staging) — image builds
- [`entrypoint.sh`](./entrypoint.sh) — container entrypoint

## Backups

Metabase's database has two independent backup mechanisms:

- [`backup-cloud-sql.md`](./backup-cloud-sql.md) — Cloud SQL **automated
  backups** (managed, in-place instance snapshots restored within Cloud SQL).
- [`backup-gcs-export.md`](./backup-gcs-export.md) — daily portable **`pg_dump`
  exports** to a Cloud Storage bucket (`.sql.gz` you can download or import
  anywhere).

To restore from a GCS export, follow the runbook:
[`runbooks/workflow/metabase-restore.md`](../../runbooks/workflow/metabase-restore.md).
