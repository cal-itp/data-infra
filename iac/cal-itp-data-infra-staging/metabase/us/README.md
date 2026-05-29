# Metabase database backups

This documents how backups work for the Cloud SQL Postgres instance that backs
the **staging** Metabase. The backup configuration lives in
[`sql.tf`](./sql.tf).

> **Scope:** this was rolled out to staging first (per the recommendation on
> [issue #5098](https://github.com/cal-itp/data-infra/issues/5098)). Production
> (`cal-itp-data-infra/metabase/us/sql.tf`) still uses the older policy and is a
> planned follow-up. See [Current state](#current-state) below.

## What is backed up

The Cloud SQL instance holds Metabase's **application metadata** — dashboards,
questions/cards, collections, users, permissions, and settings. It does **not**
hold the analytics data those dashboards query; that lives in BigQuery. So a
backup restore brings back the Metabase app state, not warehouse data.

## Current state

| Environment | Project | Instance | Retention | Backup location |
| --- | --- | --- | --- | --- |
| Staging | `cal-itp-data-infra-staging` | `metabase-staging` | 60 backups | `us` (multi-region) |
| Production | `cal-itp-data-infra` | `metabase` | 7 backups | `us-west2` (single region) |

Production is intentionally unchanged for now; the plan is to apply the same
configuration there once it has been validated in staging.

## How backups are configured

In [`sql.tf`](./sql.tf), the `backup_configuration` block controls backups:

```hcl
backup_configuration {
  location = "us"      # multi-region storage (geo-redundant)
  enabled  = true      # daily automated backups

  backup_retention_settings {
    retained_backups = 60
    retention_unit   = "COUNT"
  }
}
```

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
  the 61st backup is taken, the oldest is dropped.

`deletion_protection = true` on the instance prevents it from being accidentally
deleted via Terraform or `gcloud`.

> The instance is pinned to `edition = "ENTERPRISE"`, the standard (default)
> Cloud SQL edition. It is set explicitly to document intent and because it is
> the edition that supports the shared-core `db-f1-micro` tier this instance
> uses. Up to 365 automated backups can be retained, so 60 leaves plenty of
> headroom if we ever want a longer window.

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

List available backups for the staging instance:

```bash
gcloud sql backups list \
  --instance=metabase-staging \
  --project=cal-itp-data-infra-staging
```

Restore a chosen backup onto a target instance:

```bash
gcloud sql backups restore BACKUP_ID \
  --restore-instance=metabase-staging \
  --project=cal-itp-data-infra-staging
```

The number of backups you can choose from is governed by `retained_backups`
(60) and the daily schedule — multi-region storage does not add extra restore
points, it only makes the same set more durable.

## Changing the backup policy

Backups are managed entirely through Terraform. Edit the `backup_configuration`
block in `sql.tf`, open a PR, and the `Terraform Plan` workflow will post the
plan as a PR comment. On merge to `main`, `Terraform Apply` applies it.

Note: changing `location` does **not** retroactively copy existing backups to
the new location; the new policy applies to backups taken going forward.
