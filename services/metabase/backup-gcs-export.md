# Metabase backups: portable SQL dumps on Cloud Storage

This documents the **GCS export** backups for the Cloud SQL Postgres instance
that backs Metabase: a daily, transactionally-consistent `pg_dump` of the live
database, written as a compressed `.sql.gz` object to a Cloud Storage bucket.

This is **one of two independent backup mechanisms** for Metabase:

| Doc                                            | Mechanism                              | What it produces                                                        |
| ---------------------------------------------- | -------------------------------------- | ----------------------------------------------------------------------- |
| [`backup-cloud-sql.md`](./backup-cloud-sql.md) | Cloud SQL **automated backups**        | Managed, in-place instance snapshots you restore *within* Cloud SQL     |
| **`backup-gcs-export.md`** (this doc)          | Cloud SQL **`instances.export`** → GCS | A portable `.sql.gz` dump you can download, inspect, or import anywhere |

They are complementary. Automated backups are the fast, low-effort recovery
path; the GCS dumps are portable, long-lived, and survive even the loss of the
Cloud SQL instance itself. Both staging and production are implemented (staging
was rolled out first, per the recommendation on
[issue #5098](https://github.com/cal-itp/data-infra/issues/5098)).

## What is backed up

The dump captures Metabase's **application metadata** — dashboards,
questions/cards, collections, users, permissions, and settings. It does **not**
contain the analytics data those dashboards query; that lives in BigQuery. A
restore brings back the Metabase app state, not warehouse data. (Same scope as
the Cloud SQL automated backups.)

## How it works

The pipeline is identical in both environments. A Cloud Scheduler job triggers a
Cloud Workflow, which calls the Cloud SQL Admin `instances.export` API. Cloud
SQL runs `pg_dump` against the **live** database and streams a gzip-compressed
SQL dump to the bucket. There is no `pg_dump` command in the repo — the database
is managed, so the export is requested via the API and Google's infrastructure
performs it.

```
Cloud Scheduler (daily 04:00 PT)
  │  POST .../workflows/<workflow>/executions      (OAuth as the metabase-backup SA)
  ▼
Cloud Workflow                                     (runs as the metabase-backup SA)
  │  call: googleapis.sqladmin.v1.instances.export
  │        fileType=SQL, databases=[<db>], uri=gs://<bucket>/exports/<name>-<date>.sql.gz
  ▼
Cloud SQL <instance>
  │  runs pg_dump on the live DB, gzip (triggered by the .gz extension)
  ▼
GCS  gs://<bucket>/exports/<name>-<date>.sql.gz
       (written by the Cloud SQL instance's own service identity)
```

The `instances.export` connector is **blocking**: the workflow submits the
export operation and polls until it completes, so one execution equals one
finished dump.

### Identities (service accounts)

Three identities participate, per environment. Only the first is one we create.

| Identity                                                | Role in the flow                                                                | Permission                                         |
| ------------------------------------------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------- |
| `metabase-backup` (created)                             | Scheduler authenticates as it; workflow **runs as** it and calls the export API | `roles/workflows.invoker`, `roles/cloudsql.editor` |
| Cloud SQL **instance** service account (Google-managed) | Performs the dump and **writes** the object to the bucket                       | `roles/storage.objectAdmin` on the bucket          |
| Cloud Scheduler **service agent** (Google-managed)      | Mints the OAuth token for `metabase-backup` at fire time                        | auto (`cloudscheduler.serviceAgent`)               |

`metabase-backup` is **keyless** — no JSON key is generated or stored. Auth is
entirely via GCP-managed identity binding (the workflow's `service_account` and
the scheduler's `oauth_token`). Each project (staging and prod) has its own
`metabase-backup` service account, since they are separate GCP projects.

## Per-environment configuration

|                        | Staging                                       | Production                                   |
| ---------------------- | --------------------------------------------- | -------------------------------------------- |
| **Status**             | Implemented                                   | Implemented                                  |
| **Project**            | `cal-itp-data-infra-staging`                  | `cal-itp-data-infra`                         |
| **Instance**           | `metabase-staging`                            | `metabase`                                   |
| **Destination bucket** | `calitp-backups-metabase-staging` (new)       | `calitp-backups-metabase` (existing, reused) |
| **Bucket region**      | `us-west2` (single region)                    | `us-west1` (single region)                   |
| **Object path**        | `exports/metabase-staging-YYYY-MM-DD.sql.gz`  | `exports/metabase-YYYY-MM-DD.sql.gz`         |
| **Schedule**           | daily 04:00 `America/Los_Angeles`             | daily 04:00 `America/Los_Angeles`            |
| **Terraform**          | `iac/cal-itp-data-infra-staging/metabase/us/` | `iac/cal-itp-data-infra/metabase/us/`        |

Notes:

- **Production reuses the existing bucket.** `calitp-backups-metabase` already
  exists (it formerly held the decommissioned restic archive) and already has an
  `exports/` prefix. Production exports land alongside under the same prefix, so
  no new prod bucket is created. The staging bucket is the only new bucket.
- **Bucket name and region are immutable.** Staging is `us-west2` to co-locate
  with the staging Cloud SQL instance; prod stays on the existing bucket's
  `us-west1`. Changing either property means creating a new bucket — existing
  dumps are not migrated.

## Where it is configured (Terraform)

The runner service account, its project roles, the Workflow, and the Scheduler
job all live in the `metabase` module so they plan and apply as a single unit.
This is a deliberate deviation from the repo convention of defining service
accounts in the `iam` module: keeping the SA here avoids a cross-module ordering
dependency on a brand-new `iam`-module output that does not exist until `iam` is
applied, which the parallel, unordered Terraform CI cannot guarantee.

| Resource                                              | Staging                                        | Production                                     |
| ----------------------------------------------------- | ---------------------------------------------- | ---------------------------------------------- |
| `metabase-backup` SA + roles, Workflow, Scheduler job | `…/metabase/us/backups.tf`                     | `…/metabase/us/backups.tf`                     |
| Workflow definition (export step)                     | `…/metabase/us/workflows/metabase-backup.yaml` | `…/metabase/us/workflows/metabase-backup.yaml` |
| Destination bucket                                    | created in `…/metabase/us/backups.tf`          | reused; defined in `…/gcs/us`                  |
| Cloud SQL SA → bucket `objectAdmin` grant             | `…/metabase/us/backups.tf` (own bucket)        | `…/gcs/us` authoritative bucket IAM policy     |

The one structural difference: in staging the bucket is new and lives in the
`metabase` module, so the write grant is a simple additive `iam_member` there. In
production the bucket is the shared, pre-existing `calitp-backups-metabase`,
whose IAM is **authoritative** (`google_storage_bucket_iam_policy` in `gcs/us`).
Write access to that bucket is not new — the `backup-metabase` service account
has held `objectAdmin` since the old restic backups wrote as it. What changes is
the *writer*: Cloud SQL's `instances.export` writes as the **instance's** own
service identity (not as the invoking SA), so that identity is what needs the
grant. It is added directly to the authoritative policy (an additive
`iam_member` would be stripped on the next `gcs/us` apply), alongside the
existing `backup-metabase` binding rather than replacing it.

## How to restore

The export produces a standard `pg_dump` SQL file, so it can be restored with a
server-side Cloud SQL import (`gcloud sql import sql`) or piped through `psql`.
The full procedure — download, swap to a no-op image to drop connections, drop
and recreate the database, import, and verify — is documented in the runbook:

[`runbooks/workflow/metabase-restore.md`](../../runbooks/workflow/metabase-restore.md)

List available dumps (substitute the environment's bucket):

```bash
# staging
gcloud storage ls gs://calitp-backups-metabase-staging/exports/
# production
gcloud storage ls gs://calitp-backups-metabase/exports/
```

## What is NOT enabled

- **No lifecycle / retention policy.** Dumps are kept **forever** for now —
  there is no lifecycle rule deleting or downgrading old objects. A retention
  policy can be added later (e.g. transition to Coldline or expire after N
  days); it would apply to objects going forward.
- **No `--offload`.** The export runs on the primary instance. It is scheduled
  for 04:00 PT (low activity) to minimize the impact of the brief locking the
  dump requires. Serverless offload could be added if export load becomes a
  concern.

Everything is managed through Terraform: edit `backups.tf` (or the workflow
YAML) and open a PR. The bucket `name` and `location` are immutable, and the
`exports/…` object path is built in the workflow YAML.
