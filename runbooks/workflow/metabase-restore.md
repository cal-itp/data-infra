# Restoring Metabase from a Cloud SQL backup

Restore the prod Metabase database from a managed Cloud SQL backup, in place.

This is the disaster-recovery path: bring the live deployment at `https://metabase.dds.dot.ca.gov/` back to a known-good state by overwriting the prod Cloud SQL instance with one of its own backups.

For the upgrade-testing / "spin up a copy of prod to experiment with" workflow, see [`metabase-test-instance-from-prod.md`](metabase-test-instance-from-prod.md) instead.

## When to use this runbook

- Production Metabase data was lost or corrupted (accidental deletion, bad migration, etc.).
- The application database needs to be rolled back to a specific point.

This runbook is **destructive** for the live instance — the in-place restore overwrites the current Cloud SQL data. Anything created since the chosen backup is lost.

## Prerequisites

- `gcloud` CLI authenticated with `cal-itp-data-infra` project access. None of these steps require a database password.
- Authority to take prod Metabase offline for ~10–15 minutes.

## Backup retention

The `metabase` Cloud SQL instance is configured for **7 daily automated backups**, retained on a rolling basis. See [`iac/cal-itp-data-infra/metabase/us/sql.tf`](../../iac/cal-itp-data-infra/metabase/us/sql.tf). Older history is not retained — if you need point-in-time recovery beyond 7 days, you must restore from a SQL export captured separately.

## 1. Identify the backup to restore from

### gcloud

```bash
gcloud sql backups list \
  --instance=metabase \
  --project=cal-itp-data-infra
```

Note the `ID` of the chosen backup (e.g. `1778166920912`).

### Console

1. Open <https://console.cloud.google.com/sql/instances/metabase/backups?project=cal-itp-data-infra>.
2. Review the list and identify the backup to restore from. Note its window-start timestamp.

## 2. Take an on-demand backup of the current state (recommended)

Captures a recovery point you can fall back to if the restore goes wrong.

### gcloud

```bash
gcloud sql backups create \
  --instance=metabase \
  --project=cal-itp-data-infra \
  --description="pre-restore snapshot $(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

### Console

1. From the **Backups** tab, click **Create backup**.
2. Add a description like `pre-restore snapshot <ISO timestamp>` and confirm.

Wait for the operation to complete (~1 minute) before proceeding.

## 3. Park Metabase

Cloud Run instances hold pooled connections to Cloud SQL even when scaled to zero. Swap the service to a no-op image so all connections release before the restore.

### gcloud

```bash
gcloud run services update metabase \
  --image=gcr.io/cloudrun/hello \
  --min-instances=0 \
  --region=us-west2 \
  --project=cal-itp-data-infra
```

### Console

1. Open <https://console.cloud.google.com/run/detail/us-west2/metabase/revisions?project=cal-itp-data-infra>.
2. Click **Edit & Deploy New Revision**.
3. Under **Container image URL**, replace the image with `gcr.io/cloudrun/hello`.
4. Under **Autoscaling**, set **Minimum number of instances** to `0`.
5. Click **Deploy** and wait for the new revision to roll out.

`metabase.dds.dot.ca.gov` will return the Cloud Run "Hello World" page during this window.

## 4. Restore the backup

This is the destructive step. The chosen backup is written over the entire Cloud SQL instance.

### gcloud

```bash
gcloud sql backups restore <BACKUP_ID> \
  --restore-instance=metabase \
  --project=cal-itp-data-infra
```

The command waits for the restore operation to finish.

### Console

1. From the **Backups** tab, locate the chosen backup.
2. Click the three-dot menu next to it and choose **Restore**.
3. Confirm the target instance is `metabase` (in-place restore) and click **Restore**.
4. Wait for the operation to complete.

## 5. Bring Metabase back

### gcloud

Use the prod image tag and minimum-instances setting that match the deployed terraform state.

```bash
gcloud run services update metabase \
  --image=us-west2-docker.pkg.dev/cal-itp-data-infra/ghcr/cal-itp/data-infra/metabase:production \
  --min-instances=1 \
  --region=us-west2 \
  --project=cal-itp-data-infra
```

### Console

1. From the Cloud Run service page, click **Edit & Deploy New Revision**.
2. Restore the image URL to `us-west2-docker.pkg.dev/cal-itp-data-infra/ghcr/cal-itp/data-infra/metabase:production`.
3. Restore **Minimum number of instances** to `1`.
4. Click **Deploy**.

The first request after the new revision goes live triggers Metabase's startup. If the restored backup was taken on a previous Metabase version, the application schema migration runs at this point. The service returns 503 with `{"status":"initializing"}` from `/api/health` until it's complete.

## 6. Verify

### gcloud

```bash
curl -s https://metabase.dds.dot.ca.gov/api/health
# expect: {"status":"ok"}
```

### Console

1. Open <https://metabase.dds.dot.ca.gov/>, sign in, and confirm dashboards and questions reflect the restored point in time.
2. Spot-check a known-affected dashboard or question if you're restoring after a specific incident.

## Expected timeline

Measured against `metabase-restore-test` (db-g1-small, ~800 MB application DB seeded from a prod export, same Metabase version on each side of the restore). Wall-clock figures from the validation run on 2026-05-07 — actual times scale with database size.

| Phase                                                    | Measured duration                                               |
| -------------------------------------------------------- | --------------------------------------------------------------- |
| List backups (step 1)                                    | seconds                                                         |
| On-demand pre-restore backup (step 2)                    | ~60–80 s                                                        |
| Park Metabase — Cloud Run revision deploy (step 3)       | ~10 s                                                           |
| Restore from backup (step 4)                             | **~4 minutes**                                                  |
| Bring Metabase back — Cloud Run revision deploy (step 5) | ~45 s                                                           |
| Metabase startup health check returns `"ok"` (step 5–6)  | ~5–10 minutes typical against prod's normal driver reachability |
| **Total user-visible downtime**                          | **~10–15 minutes** typical                                      |

Notes on the dominant phases:

- **Restore from backup (step 4)** scales with the size of the Cloud SQL instance's storage volume — at ~800 MB the operation took 4 minutes.
- **Metabase startup** is dominated by Liquibase changelog reading + search index initialization + per-driver feature checks against every configured external database. In prod, the external databases (BigQuery, Payments DBs) are reachable, so the driver probes complete quickly. In an isolated test instance the same probes time out, dramatically extending boot time — see the comparable "Expected timeline" notes in [`metabase-test-instance-from-prod.md`](metabase-test-instance-from-prod.md).
- If the restored backup was taken on a different Metabase version, expect Liquibase to take noticeably longer as it applies migrations on top of the restored schema.

## Notes

- All steps in this runbook are server-side gcloud API calls or Cloud Run revision deploys; **no database password is required**. Earlier restic-era runbooks needed `psql` and the Cloud SQL instance password to drop/recreate the database — that's no longer necessary because `gcloud sql backups restore` is fully managed.
- `gcloud sql backups restore` operates only within the same project. To restore prod data into a different project (e.g. for upgrade testing), use the export/import workflow in [`metabase-test-instance-from-prod.md`](metabase-test-instance-from-prod.md).
- If `/api/health` returns `{"status":"initializing","progress":...}` after step 5, it is running schema migrations — leave it alone. Watch the progress value in successive polls; it should advance.
- Cloud Run logs for the running revision: <https://console.cloud.google.com/run/detail/us-west2/metabase/logs?project=cal-itp-data-infra>.
