# Restoring Metabase

Metabase runs on **Cloud Run**, backed by a **Cloud SQL Postgres** instance that
holds Metabase's *application metadata* — dashboards, questions/cards,
collections, users, permissions, and settings. It does **not** hold the
analytics data the dashboards query; that lives in BigQuery. A restore therefore
brings back the Metabase app state, not warehouse data.

There are two managed backup sources (plus any local dump you may have kept). How
they are configured is documented separately:

- [`services/metabase/backup-cloud-sql.md`](../../services/metabase/backup-cloud-sql.md)
  — Cloud SQL **automated backups** (managed, in-place instance snapshots).
- [`services/metabase/backup-gcs-export.md`](../../services/metabase/backup-gcs-export.md)
  — daily portable **`pg_dump` exports** to a Cloud Storage bucket.

This runbook is the restore procedure for both, plus restoring a local snapshot.

## Which path?

| Path  | Source                      | Use when                                                                                                 | Note                                                                   |
| ----- | --------------------------- | -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| **A** | Cloud SQL automated backup  | Fastest recovery; instance is healthy and you want a recent nightly snapshot                             | Restores **in place** and overwrites **all** databases on the instance |
| **B** | GCS export dump (`.sql.gz`) | You need a specific dated dump, want to inspect it first, are migrating, or the instance itself was lost | Portable; imported into a fresh database                               |
| **C** | Local SQL snapshot          | You have a `.sql`/`.sql.gz` file on disk (e.g. a preserved older snapshot)                               | Same import mechanics as B                                             |

Paths B and C share most steps with A's deactivate/reactivate/verify wrappers.

## Prerequisites

- `gcloud` CLI authenticated with access to the target project
  (`roles/cloudsql.admin` and `roles/run.admin`, or equivalent).
- *Only for the optional direct DB connection in step 6:* `psql`
  (`brew install libpq && brew link --force libpq`) and the **v2** Cloud SQL Auth
  Proxy (`gcloud components install cloud-sql-proxy` or `brew install cloud-sql-proxy`). Step 6 locates the proxy whether it's on PATH or in the
  gcloud SDK `bin/`.

## 0. Set environment for the target instance

Every command below is parameterized. Paste **one** block.

```bash
# ---- Production ----
export PROJECT_ID=cal-itp-data-infra
export REGION=us-west2
export RUN_SERVICE=metabase
export SQL_INSTANCE=metabase
export DB_NAME=metabase
export DB_USER=metabase
export DB_SECRET=metabase-password                     # only for optional direct DB access
export BACKUP_BUCKET=calitp-backups-metabase          # us-west1, NEARLINE
export EXPORT_PREFIX=metabase                          # exports/metabase-YYYY-MM-DD.sql.gz
export METABASE_URL=https://metabase.dds.dot.ca.gov
# IMAGE is read live from the running service in step 1 (not hardcoded here), so
# the runbook always reactivates with whatever the service is currently set to.
```

```bash
# ---- Staging ----
export PROJECT_ID=cal-itp-data-infra-staging
export REGION=us-west2
export RUN_SERVICE=metabase-staging
export SQL_INSTANCE=metabase-staging
export DB_NAME=metabase-staging
export DB_USER=metabase-staging
export DB_SECRET=metabase-staging-password             # only for optional direct DB access
export BACKUP_BUCKET=calitp-backups-metabase-staging   # us-west2
export EXPORT_PREFIX=metabase-staging                  # exports/metabase-staging-YYYY-MM-DD.sql.gz
export METABASE_URL=https://metabase-staging.dds.dot.ca.gov
# IMAGE is read live from the running service in step 1 (not hardcoded here), so
# the runbook always reactivates with whatever the service is currently set to.
```

## 1. Deactivate Metabase

Quiesce the app so it isn't writing during the restore. This is **recommended**
for Path A and **required** for Paths B/C (you can't drop the database while
Metabase holds connections). Swapping to a no-op image forces a new revision and
releases all database connections.

**CLI**

```bash
# Read the image the service is set to (don't hardcode it) so step 5 redeploys
# the same reference. This is normally the :staging / :production tag — the value
# Terraform declares — so reactivating with it keeps the service aligned with IaC.
# (Cloud Run separately pins each running revision to the resolved @sha256 digest;
# that's expected and not needed here.)
export IMAGE=$(gcloud run services describe "$RUN_SERVICE" \
  --region="$REGION" --project="$PROJECT_ID" \
  --format='value(spec.template.spec.containers[0].image)')
echo "Will restore image: $IMAGE"

# Swap to a no-op image to release all DB connections
gcloud run services update "$RUN_SERVICE" \
  --image=us-docker.pkg.dev/cloudrun/container/hello \
  --min-instances=0 \
  --region="$REGION" \
  --project="$PROJECT_ID"
```

**Console**

1. Cloud Run → **`$RUN_SERVICE`** → **Edit & deploy new revision**.
2. **First copy the current Container image URL and save it** — the value shown
   may be a `:staging`/`:production` tag or a resolved `@sha256:` digest; either
   is fine to paste back in step 5. Then set the field to `us-docker.pkg.dev/cloudrun/container/hello`.
3. Under **Autoscaling**, set **Minimum number of instances** to `0`.
4. **Deploy**. Wait until the new revision is serving 100% of traffic.

______________________________________________________________________

## Path A — Restore an automated Cloud SQL backup (in place)

> ⚠️ This **overwrites every database on the instance** with the backup's
> contents. To inspect data before committing, restore into a *clone* instead
> (`gcloud sql instances clone "$SQL_INSTANCE" metabase-restore-tmp --project="$PROJECT_ID"`)
> and point a throwaway service at it.

**CLI**

```bash
# List available automated backups (newest first)
gcloud sql backups list \
  --instance="$SQL_INSTANCE" \
  --project="$PROJECT_ID"

# Restore a chosen backup onto the same instance
gcloud sql backups restore BACKUP_ID \
  --restore-instance="$SQL_INSTANCE" \
  --project="$PROJECT_ID"
```

**The restore is a long-running operation.** The CLI's client-side wait gives up
after ~10 minutes and prints *"Operation … is taking longer than expected"* while
the restore continues **server-side** — that is the wait timing out, not a
failure. Check status with the GA commands (no `beta` component needed):

```bash
# one-shot status of the restore operation (id is printed by the restore command)
gcloud sql operations describe OPERATION_ID --project="$PROJECT_ID"

# or poll the instance until it returns to RUNNABLE
gcloud sql instances describe "$SQL_INSTANCE" \
  --project="$PROJECT_ID" --format='value(state)'
```

Wait for the operation `status: DONE` (instance `RUNNABLE`) before reactivating
in step 5 — redeploying Metabase mid-restore will fail to connect.

**Console**

1. Cloud SQL → **`$SQL_INSTANCE`** → **Backups**.
2. Find the backup by timestamp → **⋮** → **Restore**.
3. Confirm the target instance and **Restore**. The instance is unavailable
   while the restore runs.

The number of restore points is governed by retention (60 automated backups ≈ 60
days) — see [`backup-cloud-sql.md`](../../services/metabase/backup-cloud-sql.md).
When done, continue to [Reactivate](#5-reactivate-metabase).

______________________________________________________________________

## Path B — Restore from a GCS export dump

The daily exports are portable `pg_dump` files at
`gs://$BACKUP_BUCKET/exports/$EXPORT_PREFIX-YYYY-MM-DD.sql.gz`.

### B1. Pick a dump

```bash
gcloud storage ls "gs://$BACKUP_BUCKET/exports/"
# choose one, e.g.:
export EXPORT_OBJECT="gs://$BACKUP_BUCKET/exports/$EXPORT_PREFIX-$(date +%F).sql.gz"
```

### B2. Drop and recreate the database

Requires Metabase deactivated (step 1) so there are no active connections.

```bash
gcloud sql databases delete "$DB_NAME" \
  --instance="$SQL_INSTANCE" --project="$PROJECT_ID" --quiet

gcloud sql databases create "$DB_NAME" \
  --instance="$SQL_INSTANCE" --project="$PROJECT_ID" \
  --charset=UTF8 --collation=en_US.UTF8
```

### B3. Import

`gcloud sql import sql` runs server-side and reads the gzipped dump directly from
the bucket — the Cloud SQL instance's own service identity already has write/read
access to `$BACKUP_BUCKET`, so no copy step is needed.

**CLI**

```bash
gcloud sql import sql "$SQL_INSTANCE" "$EXPORT_OBJECT" \
  --database="$DB_NAME" \
  --user="$DB_USER" \
  --project="$PROJECT_ID" \
  --quiet
```

**Console**

1. Cloud SQL → **`$SQL_INSTANCE`** → **Import**.
2. **Source**: browse to the object under `gs://$BACKUP_BUCKET/exports/`.
3. **File format**: SQL. **Destination database**: `$DB_NAME`.
4. **Import**.

Continue to [Reactivate](#5-reactivate-metabase).

______________________________________________________________________

## Path C — Restore from a local SQL snapshot

For a dump you already hold on disk (e.g. a preserved pre-GCP snapshot). Same
mechanics as Path B — stage the file in the bucket, then import.

```bash
# .sql or .sql.gz both work; gzip is auto-detected on import
gcloud storage cp ./snapshot.sql.gz "gs://$BACKUP_BUCKET/restore/snapshot.sql.gz"
```

Then run **B2** (drop/recreate) and **B3** with
`export EXPORT_OBJECT="gs://$BACKUP_BUCKET/restore/snapshot.sql.gz"`.

Remove the staged object afterward:

```bash
gcloud storage rm "gs://$BACKUP_BUCKET/restore/snapshot.sql.gz"
```

______________________________________________________________________

## 5. Reactivate Metabase

Restore the real image so Metabase comes back up.

**CLI**

```bash
gcloud run services update "$RUN_SERVICE" \
  --image="$IMAGE" \
  --min-instances=1 \
  --region="$REGION" \
  --project="$PROJECT_ID"
```

**Console**

1. Cloud Run → **`$RUN_SERVICE`** → **Edit & deploy new revision**.
2. Container image URL → the image you saved in step 1 (the value of `$IMAGE`).
3. **Minimum number of instances** → `1`.
4. **Deploy**.

## 6. Verify

Confirm Metabase is back up:

```bash
curl -s "$METABASE_URL/api/health"   # expect {"status":"ok"}
```

If it returns `{"status":"initializing","progress":…}` instead, schema
migrations are running — normal after a restore; see Notes.

Then open the site and sanity-check the app: log in, confirm dashboards and
questions render, and that collections and permissions look accurate. In a real
recovery there is no prior dataset to diff against, so this visual check of the
restored content against what you expect *is* the verification.

### Optional: connect to the database directly

Browser checks are enough to verify a restore; this is only for deeper poking
(e.g. running ad-hoc queries). Easiest is through the **Cloud SQL Auth Proxy**,
which tunnels via your gcloud/IAM credentials — **no IP allowlisting needed**
(requires `cloud-sql-proxy`, see Prerequisites):

```bash
# locate the proxy: prefer PATH, else the gcloud SDK bin copy
PROXY=$(command -v cloud-sql-proxy \
  || echo "$(gcloud info --format='value(installation.sdk_root)')/bin/cloud-sql-proxy")

CONN=$(gcloud sql instances describe "$SQL_INSTANCE" \
  --project="$PROJECT_ID" --format='value(connectionName)')

# start the proxy in the background; wait until it logs "ready for new
# connections" before connecting (sleep covers the auth + bind startup race)
"$PROXY" "$CONN" &
sleep 5

# DB password (Secret Manager; write-only, so not in Terraform state)
export PGPASSWORD=$(gcloud secrets versions access latest \
  --secret="$DB_SECRET" --project="$PROJECT_ID")

psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME"
```

At the `=>` prompt you can run ad-hoc SQL — e.g. a quick row-count sanity check:

```sql
SELECT count(*) FROM core_user;
SELECT count(*) FROM report_dashboard;
SELECT count(*) FROM report_card;
```

After you finish (`\q` to exit psql), stop the proxy:

```bash
kill %1
```

Or run SQL in the browser with **Cloud SQL Studio** (Console → SQL →
`$SQL_INSTANCE` → Cloud SQL Studio) — no client or proxy needed.

> Connecting `psql` straight to the instance's **public IP** instead works only
> if your client IP is in the instance's **authorized networks**. The Auth Proxy
> avoids this. (Older `gcloud sql connect` used to allowlist your IP as a side
> effect; the current v2 version requires the proxy, so prefer the proxy above
> rather than editing authorized networks, which is an all-or-nothing replace.)

## Expected timeline

Staging's metadata database is small (tens of MB). Production's is substantially
larger — its full SQL export ran **~800 MB** in the May 2026 recovery exercise
(#4864) — but operations are still minutes, not hours. Rough expectations:

| Step                              | Typical duration                                                                                   |
| --------------------------------- | -------------------------------------------------------------------------------------------------- |
| Deactivate / reactivate (each)    | ~1–2 min (Cloud Run revision rollout)                                                              |
| Path A — automated backup restore | ~5–20 min, scaling with instance storage — can exceed the CLI's ~10-min wait; instance unavailable |
| Path B — drop/recreate + import   | seconds to recreate; a few minutes to import                                                       |
| First Metabase startup            | a few minutes if it runs schema migrations — watch Cloud Run logs                                  |

Measured reference points: the May 2026 #4864 exercise restored an ~800 MB
database in **~4 min** (db-g1-small test instance), with the on-demand
pre-restore backup taking ~60–80 s; the staging dry-run of this runbook measured
**~15 min** for the restore step.

Plan for a **~15–30 minute** maintenance window end-to-end including
verification.

## Testing a restore (dry run)

Use this to validate the procedure end-to-end **in staging** without risk (paste
the Staging block in
[step 0](#0-set-environment-for-the-target-instance)). Unlike a real recovery —
where the data is already gone — a dry run lets you **snapshot the current
database first and restore from that exact snapshot**, so the worst case is you
end up precisely where you started.

1. **Deactivate Metabase** — follow [step 1](#1-deactivate-metabase). The Cloud
   SQL instance stays up; only the app comes down, so connections are released
   and the snapshot below is taken with nothing writing to the database.

2. **Take an on-demand snapshot of the current state:**

   ```bash
   gcloud sql backups create \
     --instance="$SQL_INSTANCE" \
     --project="$PROJECT_ID" \
     --description="dry-run $(date +%F)"
   ```

3. **Find the new backup's ID:**

   ```bash
   gcloud sql backups list \
     --instance="$SQL_INSTANCE" --project="$PROJECT_ID" --limit=5
   ```

4. **Restore from it** — run **Path A** with the `BACKUP_ID` from the previous
   step. Because you just took it, this returns the instance to its pre-test
   state.

   ```bash
   gcloud sql backups restore BACKUP_ID \
     --restore-instance="$SQL_INSTANCE" \
     --project="$PROJECT_ID"
   ```

5. **Reactivate Metabase** — [step 5](#5-reactivate-metabase).

6. **Verify** — [step 6](#6-verify): Metabase comes back up and its dashboards
   and collections look right, confirming the
   deactivate → restore → reactivate loop works.

> To dry-run **Path B** instead, trigger an on-demand export rather than a
> backup (manually execute the `metabase-backup` Cloud Workflow, which writes a
> fresh `exports/$EXPORT_PREFIX-…sql.gz`), then import that object per Path B.

> For zero staging downtime, restore the snapshot into a clone
> (`gcloud sql instances clone "$SQL_INSTANCE" metabase-dryrun-tmp --project="$PROJECT_ID"`)
> and point a throwaway service at it instead — though that skips exercising
> steps 1 and 5.

## Notes

- A restore affects **only** Metabase's app metadata. The BigQuery analytics
  data the dashboards query is untouched.
- **No database password is needed for any path** — deactivate/reactivate,
  Paths A/B/C, and verification are all server-side `gcloud` calls or Cloud Run
  revision deploys. Only the optional direct-connection section reads the
  Secret Manager password.
- `deletion_protection = true` on the instance blocks accidental deletion but
  does **not** block an in-place backup restore (Path A).
- **Point-in-time recovery (PITR) is not enabled**, so the available restore
  points are the daily automated backups (Path A) and the daily GCS export dumps
  (Path B) — not arbitrary timestamps.
- **Schema migrations on first startup.** Metabase auto-migrates its schema when
  the running application version is newer than the restored database's schema
  version. This is common after a restore — the deployed image (`:staging` /
  `:production`) may be newer than the backup you restored — so the first startup
  after reactivation can be slow. While migrating, `/api/health` returns
  `{"status":"initializing","progress":…}` — leave it be and confirm `progress`
  advances across polls; the Cloud Run logs show the migration detail.
- For how the backups themselves are configured (retention, multi-region, the
  export workflow/scheduler), see the two backup docs linked at the top and
  [`services/metabase/README.md`](../../services/metabase/README.md).
