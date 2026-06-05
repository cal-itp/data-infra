# Metabase backups: Cloud SQL automated backups

This documents how backups work for the Cloud SQL Postgres instances that back
Metabase. The backup configuration lives in each environment's `sql.tf`:

- Staging: [`iac/cal-itp-data-infra-staging/metabase/us/sql.tf`](../../iac/cal-itp-data-infra-staging/metabase/us/sql.tf)
- Production: [`iac/cal-itp-data-infra/metabase/us/sql.tf`](../../iac/cal-itp-data-infra/metabase/us/sql.tf)

This is one of two independent backup mechanisms — see
[`backup-gcs-export.md`](./backup-gcs-export.md) for the portable `pg_dump`
exports to Cloud Storage.

## What is backed up

The Cloud SQL instance holds Metabase's **application metadata** — dashboards,
questions/cards, collections, users, permissions, and settings. It does **not**
hold the analytics data those dashboards query; that lives in BigQuery. So a
backup restore brings back the Metabase app state, not warehouse data.

## Current state

| Environment | Project                      | Instance           | Retention  | Backup location     |
| ----------- | ---------------------------- | ------------------ | ---------- | ------------------- |
| Staging     | `cal-itp-data-infra-staging` | `metabase-staging` | 60 backups | `us` (multi-region) |
| Production  | `cal-itp-data-infra`         | `metabase`         | 60 backups | `us` (multi-region) |

Staging was rolled out first (per the recommendation on
[issue #5098](https://github.com/cal-itp/data-infra/issues/5098)); production
now matches it.

## How backups are configured

The `backup_configuration` block in `sql.tf` controls backups:

- **`enabled = true`** — Cloud SQL takes an **automated daily backup**. Each
  backup is a full snapshot of the instance (Google stores them incrementally
  under the hood). Google picks the backup time unless a `start_time` is set.
- **`location = "us"`** — backups are stored in the `us` **multi-region**, so
  they are replicated across multiple US regions. If `us-west2` (where the
  instance lives) has a regional outage, the backups survive. The backup
  storage location is independent of where you restore to.
- **`retained_backups = 60` / `retention_unit = "COUNT"`** — Cloud SQL keeps
  the **60 most recent automated backups**. This is a *count*, not a number of
  days. With the default daily cadence, 60 backups ≈ 60 days of history. When
  the 61st backup is taken, the oldest is dropped. (Up to 365 can be retained,
  so 60 leaves headroom for a longer window later.)

`deletion_protection = true` on the instance prevents it from being accidentally
deleted via Terraform or `gcloud`. The instance is pinned to
`edition = "ENTERPRISE"` (the default edition that supports the shared-core
tiers these instances use); it is set explicitly to document intent.

## What is NOT enabled

- **Point-in-time recovery (PITR).** PITR (`enable_point_in_time_recovery`) lets
  you restore to *any* moment using transaction logs, not just to a nightly
  snapshot. It is currently off, so the available restore points are the daily
  automated backups only. Enabling it would add more granular recovery at the
  cost of extra storage for write-ahead logs.

## How to restore

Restores are a manual, deliberate operation done with `gcloud` (or the Cloud
Console). **Restoring onto an existing instance overwrites it**, so prefer
restoring into a new/temporary instance to inspect data first.

List available backups (substitute the environment's instance/project):

```bash
# production
gcloud sql backups list \
  --instance=metabase \
  --project=cal-itp-data-infra
```

Restore a chosen backup onto a target instance:

```bash
gcloud sql backups restore BACKUP_ID \
  --restore-instance=metabase \
  --project=cal-itp-data-infra
```

The number of backups you can choose from is governed by `retained_backups`
(60) and the daily schedule — multi-region storage does not add extra restore
points, it only makes the same set more durable.

Backups are managed entirely through Terraform: edit the `backup_configuration`
block in `sql.tf` and open a PR. Note that changing `location` does **not**
retroactively copy existing backups to the new location; the new policy applies
to backups taken going forward.
