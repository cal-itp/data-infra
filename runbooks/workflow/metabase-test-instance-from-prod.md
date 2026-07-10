# Spinning up a Metabase test instance from a prod snapshot

Provision a temporary, isolated Metabase deployment in `cal-itp-data-infra-staging` seeded with a recent snapshot of the prod application database. Useful for:

- **Validating Metabase upgrades** before deploying to prod (the application's first-boot schema migration runs against real data, surfacing any incompatibilities).
- **Validating the restore runbook** itself periodically (annual exercise — see [issue #4864](https://github.com/cal-itp/data-infra/issues/4864)).
- **Investigating bugs or data anomalies** without touching production.

For in-place disaster-recovery against the prod instance itself, see [`metabase-restore.md`](metabase-restore.md) instead.

## When *not* to use this runbook

- Don't use this for in-place rollback — `gcloud sql backups restore` against the prod instance is far simpler. See `metabase-restore.md`.
- The existing `metabase-staging` deployment in `cal-itp-data-infra-staging` is **not** a prod snapshot — it's an empty staging environment used by the team for testing new dashboards. Don't destroy or re-seed it; spin up a separate temp instance per this runbook.

## Prerequisites

- `gcloud` CLI authenticated against both `cal-itp-data-infra` (prod, read-only for the export step) and `cal-itp-data-infra-staging` (write, for the temp resources).
- The prod Metabase Cloud SQL service agent has `roles/storage.objectAdmin` on `gs://calitp-backups-metabase` (provisioned by [`iac/cal-itp-data-infra/gcs/us/storage_bucket_iam_policy.tf`](../../iac/cal-itp-data-infra/gcs/us/storage_bucket_iam_policy.tf)). Without this the export in step 1 fails.
- The unified Metabase image is published at `ghcr.io/cal-itp/data-infra/metabase:staging` (built from [`services/metabase/Dockerfile`](../../services/metabase/Dockerfile)). It auto-creates the Cloud SQL Unix-socket symlink at runtime based on the `CLOUD_SQL_INSTANCE_CONNECTION_NAME` env var, so the same image works against any Cloud SQL instance.

A throwaway temp instance like the one this runbook produces costs roughly **$2–5/day** (db-g1-small Cloud SQL + Cloud Run min=1) — tear it down promptly with the cleanup section.

## Choose names and the connection name format

Use a unique, descriptive name for each temp deployment so multiple validations can run in parallel without clashing. Throughout this runbook the placeholder is `metabase-restore-test`; replace with your own.

```bash
export PROJECT=cal-itp-data-infra-staging
export INSTANCE=metabase-restore-test
export REGION=us-west2
export CONNECTION_NAME="${PROJECT}:${REGION}:${INSTANCE}"
```

## 1. Export prod database to GCS

Server-side `pg_dump` from the prod Cloud SQL instance into the existing backups bucket. Off-peak hours (early morning Pacific) are best — the export reads the live database.

### gcloud

```bash
gcloud sql export sql metabase \
  "gs://calitp-backups-metabase/exports/metabase-$(date -u +%Y-%m-%d).sql" \
  --database=metabase \
  --project=cal-itp-data-infra
```

### Console

1. Open <https://console.cloud.google.com/sql/instances/metabase/overview?project=cal-itp-data-infra>.
2. Click **Export** in the toolbar.
3. **File format**: SQL.
4. **Database for export**: `metabase`.
5. **Storage path**: `calitp-backups-metabase/exports/metabase-<YYYY-MM-DD>.sql`.
6. Click **Export** and wait for it to finish (status shows in the **Operations** tab).

## 2. Create the temp Cloud SQL instance

Match the prod tier and Postgres version so first-boot schema migration timing approximates what prod would experience. Backup config is enabled so you can also test the restore runbook against this instance later.

### gcloud

```bash
gcloud sql instances create "$INSTANCE" \
  --database-version=POSTGRES_18 \
  --region="$REGION" \
  --tier=db-g1-small \
  --edition=ENTERPRISE \
  --backup \
  --backup-start-time=10:00 \
  --retained-backups-count=7 \
  --backup-location="$REGION" \
  --project="$PROJECT"
```

### Console

1. Open <https://console.cloud.google.com/sql/choose-instance-engine?project=cal-itp-data-infra-staging>, choose **PostgreSQL**.
2. **Instance ID**: `metabase-restore-test`.
3. **Database version**: `PostgreSQL 18`.
4. **Edition**: Enterprise; **Preset**: Sandbox; **Machine type**: `db-g1-small`.
5. **Region**: `us-west2`.
6. Expand **Data Protection**, leave **Automated backups** enabled, set retention to 7.
7. Click **Create instance** and wait until the state is **Runnable** (~2 minutes).

## 3. Set the postgres user password

Needed only for the import step's `--user=postgres` argument and for any direct `psql` introspection. Cloud Run won't use it (it talks to the instance via the mounted Unix socket and the unified image creates that automatically).

### gcloud

```bash
POSTGRES_PASS=$(openssl rand -hex 24)
echo "$POSTGRES_PASS" > "/tmp/${INSTANCE}-postgres-pass"
chmod 600 "/tmp/${INSTANCE}-postgres-pass"

gcloud sql users set-password postgres \
  --instance="$INSTANCE" \
  --password="$POSTGRES_PASS" \
  --project="$PROJECT"
```

### Console

1. From the temp instance page, open the **Users** tab.
2. Find the `postgres` user, click the three-dot menu and choose **Change password**.
3. Generate a password (or paste one), copy it somewhere local, and confirm.

## 4. Create the metabase database

### gcloud

```bash
gcloud sql databases create metabase \
  --instance="$INSTANCE" \
  --project="$PROJECT"
```

### Console

1. From the temp instance page, open the **Databases** tab.
2. Click **Create database**, name it `metabase`, click **Create**.

## 5. Grant the temp instance read access to the prod export

The temp Cloud SQL instance has its own per-instance service agent (a `p<staging-project-number>-…@gcp-sa-cloud-sql.iam.gserviceaccount.com` SA, distinct from the prod instance's). To import a SQL file from the prod project's GCS bucket, that staging-side service agent needs `roles/storage.objectViewer` on the bucket.

This is intentionally a **manual, ephemeral** grant managed alongside the temp instance — the binding is removed in cleanup once the test instance is torn down. Persistent automation belongs in terraform if a use case justifies it.

### gcloud

```bash
TEMP_SA=$(gcloud sql instances describe "$INSTANCE" \
  --project="$PROJECT" \
  --format='value(serviceAccountEmailAddress)')

gcloud storage buckets add-iam-policy-binding gs://calitp-backups-metabase \
  --member="serviceAccount:${TEMP_SA}" \
  --role="roles/storage.objectViewer" \
  --project=cal-itp-data-infra
```

### Console

1. On the temp instance's **Overview** page, copy the **Service account** email under **Connect to this instance**.
2. Open <https://console.cloud.google.com/storage/browser/calitp-backups-metabase;tab=permissions?project=cal-itp-data-infra>.
3. Click **Grant access**.
4. **New principals**: paste the service account email.
5. **Role**: `Storage Object Viewer`.
6. Click **Save**.

## 6. Import the export

### gcloud

```bash
gcloud sql import sql "$INSTANCE" \
  "gs://calitp-backups-metabase/exports/metabase-$(date -u +%Y-%m-%d).sql" \
  --database=metabase \
  --user=postgres \
  --project="$PROJECT" \
  --quiet
```

### Console

1. From the temp instance page, click **Import** in the toolbar.
2. **Source**: choose the SQL file in `gs://calitp-backups-metabase/exports/...`.
3. **File format**: SQL.
4. **Database**: `metabase`.
5. **User**: `postgres`.
6. Click **Import** and wait for the operation to finish.

## 7. Deploy the Metabase Cloud Run service

The unified image creates the Cloud SQL Unix-socket symlink at runtime from `CLOUD_SQL_INSTANCE_CONNECTION_NAME`. No per-instance image build is required.

### gcloud

```bash
POSTGRES_PASS=$(cat "/tmp/${INSTANCE}-postgres-pass")

gcloud run deploy "$INSTANCE" \
  --image=us-west2-docker.pkg.dev/cal-itp-data-infra-staging/ghcr/cal-itp/data-infra/metabase:staging \
  --region="$REGION" \
  --platform=managed \
  --no-allow-unauthenticated \
  --service-account=metabase-service-account@cal-itp-data-infra-staging.iam.gserviceaccount.com \
  --add-cloudsql-instances="$CONNECTION_NAME" \
  --set-env-vars="^@^MB_DB_TYPE=postgres@MB_DB_DBNAME=metabase@MB_DB_HOST=127.0.0.1@MB_DB_USER=postgres@MB_DB_PASS=${POSTGRES_PASS}@JAVA_OPTS=-Xmx2048m@CLOUD_SQL_INSTANCE_CONNECTION_NAME=${CONNECTION_NAME}" \
  --min-instances=1 \
  --memory=2Gi \
  --cpu=1 \
  --port=3000 \
  --timeout=300 \
  --project="$PROJECT"
```

### Console

01. Open <https://console.cloud.google.com/run/create?project=cal-itp-data-infra-staging>.
02. **Service name**: `metabase-restore-test`.
03. **Region**: `us-west2`.
04. **Container image URL**: `us-west2-docker.pkg.dev/cal-itp-data-infra-staging/ghcr/cal-itp/data-infra/metabase:staging`.
05. **Authentication**: Require authentication.
06. **CPU allocation**: CPU is only allocated during request processing.
07. Under **Containers → Edit container**:
    - **Resources**: 1 CPU, 2 GiB memory.
    - **Container port**: `3000`.
    - **Environment variables**: set `MB_DB_TYPE=postgres`, `MB_DB_DBNAME=metabase`, `MB_DB_HOST=127.0.0.1`, `MB_DB_USER=postgres`, `MB_DB_PASS=<your password>`, `JAVA_OPTS=-Xmx2048m`, `CLOUD_SQL_INSTANCE_CONNECTION_NAME=cal-itp-data-infra-staging:us-west2:metabase-restore-test`.
08. Under **Cloud SQL connections**, add the temp instance's connection name.
09. Under **Networking** / Service account, choose `metabase-service-account@cal-itp-data-infra-staging.iam.gserviceaccount.com`.
10. Under **Autoscaling**, set **Minimum number of instances** to `1`.
11. Click **Create**.

## 8. Wait for first-boot schema migration

The first time Metabase connects to the imported database, it runs Liquibase migrations to bring the application schema in line with the running version. With prod-sized data this can take **5–10 minutes**.

### gcloud

```bash
URL=$(gcloud run services describe "$INSTANCE" \
  --region="$REGION" \
  --project="$PROJECT" \
  --format='value(status.url)')

TOKEN=$(gcloud auth print-identity-token)
until curl -s -H "Authorization: Bearer $TOKEN" "$URL/api/health" | grep -q '"ok"'; do
  curl -s -H "Authorization: Bearer $TOKEN" "$URL/api/health"; echo
  sleep 30
done
echo "Ready: $URL"
```

### Console

1. From the Cloud Run service page, copy the service URL.
2. With an authorized session (or a `gcloud auth print-identity-token` bearer header) hit `${URL}/api/health` and watch for `{"status":"ok"}`.
3. Open the service URL in your browser to log into the temp instance once it's ready.

## 9. Use it

The temp instance has the same users, dashboards, and questions as prod at the moment of the export. You can log in with any prod user's credentials. Make whatever destructive changes you need — they are isolated to the temp instance.

To exercise the **restore runbook** against this instance instead of prod, follow [`metabase-restore.md`](metabase-restore.md) substituting `metabase-restore-test` for the prod instance/service names.

## 10. Tear down

When the test is finished, remove all resources promptly to stop billing and avoid drift from the live IAM policy on `gs://calitp-backups-metabase`.

### gcloud

```bash
gcloud run services delete "$INSTANCE" --region="$REGION" --project="$PROJECT" --quiet

gcloud sql instances delete "$INSTANCE" --project="$PROJECT" --quiet

gcloud storage buckets remove-iam-policy-binding gs://calitp-backups-metabase \
  --member="serviceAccount:${TEMP_SA}" \
  --role="roles/storage.objectViewer" \
  --project=cal-itp-data-infra

gsutil rm "gs://calitp-backups-metabase/exports/metabase-$(date -u +%Y-%m-%d).sql"

rm "/tmp/${INSTANCE}-postgres-pass"
```

### Console

1. **Cloud Run** → `metabase-restore-test` → **Delete**.
2. **Cloud SQL** → `metabase-restore-test` → **Delete**. (You may need to disable deletion protection first — see the **Edit** screen.)
3. **GCS** → `calitp-backups-metabase` → **Permissions** tab → remove the temp instance's service account binding.
4. **GCS** → `calitp-backups-metabase` → `exports/metabase-<date>.sql` → **Delete**.

## Expected timeline

Measured from the validation run on 2026-05-07 (prod metabase ~800 MB SQL export, db-g1-small temp Cloud SQL, db-g1-small Cloud Run with 1 vCPU / 2 GiB).

| Phase                                      | Measured duration              |
| ------------------------------------------ | ------------------------------ |
| Export prod DB to GCS (step 1)             | ~56 s                          |
| Create Cloud SQL instance (step 2)         | ~2:17                          |
| Set password + create database (steps 3–4) | seconds each                   |
| IAM grant for cross-project read (step 5)  | seconds                        |
| Import (step 6)                            | ~56 s                          |
| Cloud Run deploy (step 7)                  | ~45 s                          |
| Metabase first-boot startup (step 8)       | **~25–50 minutes** — see below |
| **Total wall-clock to ready instance**     | **~30–55 minutes**             |

The "Metabase first-boot startup" range reflects three components, listed in their measured order of impact:

1. **Driver feature checks against external databases**. Metabase tries to verify each configured external database (BigQuery, Payments DBs, etc.) by calling `supports?` on its driver, with a 5-second timeout per database. In a test instance these connections typically fail because the temp Cloud Run service does not have the BigQuery / Payments credentials or network reach that prod has. With a few hundred external databases configured (as in prod), this serializes into a many-minute stall — the dominant component of slow boot in the validation run.
2. **Liquibase changelog reading + search index initialization**. Metabase logged "Metabase Initialization COMPLETE in 26.4 mins" on the first boot of the validation run. Liquibase reports "no unrun migrations" quickly when the source and target Metabase versions match; the bulk is search-index bootstrap and reading hundreds of changelog files.
3. **Cloud Run cold-start churn**. Cloud Run's default request-driven CPU allocation can starve the JVM between probe requests, multiplying boot time. The validation run saw an additional ~20 min between successful deploy and JVM successfully reaching steady boot.

If first-boot is consistently slow, deploy the temp service with `--cpu-boost` and/or `--no-cpu-throttling` to keep CPU allocated during boot — that addresses (3). Components (1) and (2) scale with the size of the application database and the number of external databases configured.

Subsequent boots on the same instance after the data-restore loop is exercised do not re-run all of the above; expect ~1–2 min once the JVM warms.

If you only need to inspect the application database state (counts, individual rows, reasoning about a regression) and don't need the Metabase web UI, a much faster path is to allowlist your IP on the temp Cloud SQL instance and connect with `psql` directly using the postgres password from step 3.
