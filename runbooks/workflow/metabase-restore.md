# Restoring Metabase to Cloud Run + Cloud SQL

Restore a Metabase database backup from the Kubernetes restic repository into the Cloud SQL instance backing the Cloud Run deployment.

## Prerequisites

- `gcloud` CLI authenticated with `cal-itp-data-infra` project access
- `gsutil`
- `psql` (`brew install libpq && brew link --force libpq`)
- Restic credentials (see `.scratch/restic-envs/metabase/`)

## 1. Download the latest backup

```bash
# load restic credentials
export GOOGLE_PROJECT_ID="1005246706141"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/gcs-upload-svcacct.json"
export RESTIC_REPOSITORY="gs:calitp-backups-metabase:/"
export RESTIC_PASSWORD="..."

# list available snapshots
restic snapshots --latest=5

# dump the latest snapshot
restic dump latest /pg_dump.sql.gz > pg_dump.sql.gz
gunzip pg_dump.sql.gz
```

## 2. Get the Cloud SQL password

```bash
cd iac/cal-itp-data-infra/metabase/us
tofu init # if needed
export PGPASSWORD=$(
  tofu state pull \
  | jq -r '.resources[] | select(.type=="random_password" and .name=="metabase-database") | .instances[0].attributes.result'
)
```

## 3. Deploy a no-op image

Swap the Cloud Run service to a no-op image so Metabase releases all database connections:

```bash
gcloud run services update metabase \
  --image=gcr.io/cloudrun/hello \
  --min-instances=0 \
  --region=us-west2 \
  --project=cal-itp-data-infra
```

## 4. Drop and recreate the database

```bash
gcloud sql databases delete metabase \
  --instance=metabase \
  --project=cal-itp-data-infra \
  --quiet

gcloud sql databases create metabase \
  --instance=metabase \
  --project=cal-itp-data-infra \
  --charset=UTF8 \
  --collation=en_US.UTF8
```

## 5. Import the backup

Upload to GCS and run a server-side import (more reliable than piping through psql for large dumps):

```bash
gsutil cp pg_dump.sql gs://calitp-backups-metabase/pg_dump.sql

gcloud sql import sql metabase \
  gs://calitp-backups-metabase/pg_dump.sql \
  --database=metabase \
  --user=metabase \
  --project=cal-itp-data-infra \
  --quiet
```

## 6. Restore the Metabase service

```bash
gcloud run services update metabase \
  --image=us-west2-docker.pkg.dev/cal-itp-data-infra/ghcr/cal-itp/data-infra/metabase:production \
  --min-instances=1 \
  --region=us-west2 \
  --project=cal-itp-data-infra
```

## 7. Verify

```bash
# get the instance IP
export PGHOST=$(gcloud sql instances describe metabase \
  --project=cal-itp-data-infra \
  --format='value(ipAddresses[0].ipAddress)')

# allowlist your IP (the psql connection will fail without a password, but the allowlisting takes effect)
gcloud sql connect metabase --database=postgres --user=metabase --project=cal-itp-data-infra || true

# then connect directly with psql
psql -h "$PGHOST" -U metabase -d metabase \
  -c "SELECT count(*) FROM core_user; SELECT count(*) FROM report_dashboard; SELECT count(*) FROM report_card;"

# check health
curl -s https://metabase.dds.dot.ca.gov/api/health
```

## 8. Clean up

```bash
gsutil rm gs://calitp-backups-metabase/pg_dump.sql
```

## Notes

- Metabase auto-migrates its schema on startup when the application version is newer than the database schema version. Check Cloud Run logs if startup is slow.
- The backup chart (`kubernetes/apps/charts/postgresql-backup`) uses `pg_dump --no-owner --no-privileges`, so dumps are portable across different database users without any transformation.
