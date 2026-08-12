# Upgrading Metabase

Metabase runs on Cloud Run in both environments, built from a single image
([`services/metabase/Dockerfile`](../../services/metabase/Dockerfile)) whose
`FROM` line pins the Metabase version. An upgrade is therefore three things: a
version bump merged to `main`, a deploy to staging, and a deploy to production.

The version running is whatever the pinned base image says, so the pin on `main`
is the source of truth and every upgrade starts with a pull request.

> ⚠️ **Metabase upgrades run irreversible schema migrations** against the
> application database on first boot of the new version. Downgrading the image
> afterwards is *not* a rollback — the old version may refuse to start against
> the migrated schema. A real rollback restores the database (see
> [Rollback](#rollback)). Take the pre-upgrade backup seriously.

## Scope of this runbook

| Change                                                                          | Use this runbook | Rehearse against prod data first |
| ------------------------------------------------------------------------------- | ---------------- | -------------------------------- |
| Patch bump within a minor line (`v0.58.7` → `v0.58.24`)                         | ✅               | Not required                     |
| Minor or major jump (`v0.58.x` → `v0.63.x`)                                     | ✅               | **Yes**                          |
| OSS → Enterprise cutover (`metabase/metabase` → `metabase/metabase-enterprise`) | ✅               | **Yes**                          |

"Rehearse against prod data" means
[`metabase-test-instance-from-prod.md`](metabase-test-instance-from-prod.md):
stand up a throwaway instance seeded with a prod dump and let the new version
migrate it. Do that **before** step 1 for anything other than a patch bump.

> **Staging is not a substitute for that rehearsal.** The `metabase-staging`
> database is a small test environment, not a copy of prod. A clean staging
> upgrade proves the image boots, the config is right, and migrations run — it
> does *not* prove they survive prod's data volume and content.

## Prerequisites

- `gcloud` CLI authenticated with `roles/run.admin` on the target project, plus
  `roles/cloudsql.admin` for the backup and rollback steps.
- Write access to the repo, to open and merge the bump PR.
- A Metabase admin login for each environment, for the post-deploy checks.

## 0. Set environment for the target instance

Every command below is parameterized. Paste **one** block, for whichever
environment you are deploying to. These use the same variable names as
[`metabase-restore.md`](metabase-restore.md), so the two runbooks compose.

```bash
# ---- Staging ----
export PROJECT_ID=cal-itp-data-infra-staging
export REGION=us-west2
export RUN_SERVICE=metabase-staging
export SQL_INSTANCE=metabase-staging
export IMAGE_TAG=us-west2-docker.pkg.dev/cal-itp-data-infra-staging/ghcr/cal-itp/data-infra/metabase:staging
export METABASE_URL=https://metabase-staging.dds.dot.ca.gov
```

```bash
# ---- Production ----
export PROJECT_ID=cal-itp-data-infra
export REGION=us-west2
export RUN_SERVICE=metabase
export SQL_INSTANCE=metabase
export IMAGE_TAG=us-west2-docker.pkg.dev/cal-itp-data-infra/ghcr/cal-itp/data-infra/metabase:production
export METABASE_URL=https://metabase.dds.dot.ca.gov
```

Both `IMAGE_TAG`s point at Artifact Registry *remote repositories* that proxy
`ghcr.io/cal-itp/data-infra/metabase`: CI builds and pushes to GHCR, and
Artifact Registry pulls through on demand.

## 1. Choose the target version

Metabase publishes OSS as `v0.x.y` (`metabase/metabase`) and Enterprise as
`v1.x.y` (`metabase/metabase-enterprise`) — **two different Docker repos**, with
matching minor and patch numbers between them.

List what is available on the line you are on:

```bash
curl -s "https://hub.docker.com/v2/repositories/metabase/metabase/tags?page_size=100&ordering=last_updated" \
  | python3 -c "import json,sys; print(*sorted({t['name'] for t in json.load(sys.stdin)['results'] if t['name'].startswith('v0.')}), sep='\n')"
```

Prefer the **highest patch on the minor line already running**: that picks up
security fixes with the smallest migration surface. Move to a new minor line only
deliberately, and only after the prod-data rehearsal above.

Pin an **exact patch version**. Do not use floating tags (`v0.58.x`,
`v1.58-lts`) — they move on their own, which means the running version can change
with no pull request and no record in git.

## 2. Bump the pin and merge

Edit the `FROM` line in [`services/metabase/Dockerfile`](../../services/metabase/Dockerfile):

```dockerfile
FROM metabase/metabase:v0.58.24
```

Open a pull request. On the PR the `Metabase Docker image` workflow
([`build-metabase.yml`](../../.github/workflows/build-metabase.yml)) **builds the
image without pushing it** — that is the gate catching a bad base image (for
instance one that no longer has `apk`, which would break the `socat` install)
before anything is published.

Merging to `main` runs the same workflow with pushing enabled, publishing the
`:staging` and `:production` tags from a single build. Wait for it to finish
before continuing.

> Both tags always point at the same digest. Staging and production differ only
> in *when* each service is redeployed to pick it up, which is what the rest of
> this runbook controls.

## 3. Record the digest you intend to deploy

The tags are mutable, so capture the digest now and verify it after each deploy.
This is what makes the deploy auditable.

> ⚠️ Not `gcloud artifacts docker images describe` — on a *remote repository* it
> reads cached inventory and can lag by days (2026-08-12: reported a May digest
> while a real pull returned the current one). Ask the registry for the manifest,
> which is the path Cloud Run takes:

```bash
curl -sI -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Accept: application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json" \
  "https://us-west2-docker.pkg.dev/v2/${PROJECT_ID}/ghcr/cal-itp/data-infra/metabase/manifests/${IMAGE_TAG##*:}" \
  | grep -i docker-content-digest
```

```bash
export TARGET_DIGEST=sha256:...   # paste the value printed above
```

Record what is running now too, so you can put the image back:

```bash
gcloud run services describe "$RUN_SERVICE" \
  --region="$REGION" --project="$PROJECT_ID" \
  --format='value(spec.template.spec.containers[0].image)'
```

## 4. Take a pre-upgrade backup

Both instances have Cloud SQL automated backups enabled (60 retained), and prod
additionally gets a nightly GCS export at 04:00 PT. Neither is necessarily
*recent* at the moment you upgrade, so take an on-demand one:

```bash
gcloud sql backups create \
  --instance="$SQL_INSTANCE" \
  --project="$PROJECT_ID" \
  --description="pre-upgrade $(date +%F)"
```

Confirm it succeeded before deploying — this is the artifact
[Rollback](#rollback) depends on:

```bash
gcloud sql backups list --instance="$SQL_INSTANCE" --project="$PROJECT_ID" \
  --sort-by=~startTime --limit=3 \
  --format='table(id,startTime,type,status,description)'
```

`--sort-by=~startTime` matters — default ordering is not guaranteed. Note the
**ID**; [Rollback](#rollback) passes it to `gcloud sql backups restore`.

Take it *immediately* before deploying. Anything written in between — dashboard
edits, saved questions — is what a restore loses. Backups are disk snapshots, so
the instance keeps serving; production takes ~70s and already runs one nightly.

**Required for production.** Skip it for staging only if you would genuinely not
care about losing that database.

## 5. Deploy

Deploying the **tag** keeps the service aligned with what Terraform declares in
`service.tf`, the same reasoning as the reactivate step in `metabase-restore.md`.
Cloud Run resolves the tag to a digest when it creates the revision and pins the
revision to it.

> **If the upgrade also changes a `.tf` file in the module, skip this step.**
> `terraform-apply` runs on merge, and the resulting revision re-resolves the tag
> by itself — no deploy command runs at all. That is how v0.58.24 shipped on
> 2026-08-12. It also changes rollback: see [Rollback](#rollback).

**CLI**

```bash
gcloud run services update "$RUN_SERVICE" \
  --image="$IMAGE_TAG" \
  --region="$REGION" \
  --project="$PROJECT_ID"
```

**Console**

1. Cloud Run → **`$RUN_SERVICE`** → **Edit & deploy new revision**.
2. Leave the container image URL as it is (already the tag) and **Deploy**. This
   creates a new revision that re-resolves the tag.

Then confirm you got the digest you meant to:

```bash
REVISION=$(gcloud run services describe "$RUN_SERVICE" \
  --region="$REGION" --project="$PROJECT_ID" \
  --format='value(status.latestCreatedRevisionName)')

gcloud run revisions describe "$REVISION" \
  --region="$REGION" --project="$PROJECT_ID" \
  --format='value(status.imageDigest)'
```

If that digest is **not** `$TARGET_DIGEST`, the tag moved between steps 3 and 5 —
someone else merged to `main`. Stop and reconcile rather than continuing. You can
deploy the exact intended build with
`--image="${IMAGE_TAG%:*}@${TARGET_DIGEST}"`, but that leaves the service holding
a digest where Terraform declares a tag, so the next `terraform apply` on that
directory will show a diff and reset it. Fine as a deliberate temporary state;
don't leave it there.

## 6. Watch the migrations

The new revision will not serve traffic until Metabase finishes its schema
migrations.

> ⚠️ **The migration must finish inside the startup probe budget.** Metabase does
> not serve `/` until Liquibase is done, so if the probe expires first Cloud Run
> kills the container *mid-migration* while it holds the `DATABASECHANGELOGLOCK`
> row, and the next boot blocks on a lock nobody owns — see [Rollback](#rollback).
>
> Budget is `initial_delay_seconds + (failure_threshold × period_seconds)`, with
> Cloud Run capping that product at 240s. Production: 60 + 48×5 = **300s**.
> Staging: 60 + 10×5 = **110s**. Staging's v0.58.7 → v0.58.24 took **65s**
> (2026-08-12). Check `service.tf` before a larger jump.

Watch them:

```bash
gcloud beta run services logs tail "$RUN_SERVICE" \
  --region="$REGION" --project="$PROJECT_ID"
```

The health endpoint reports progress meanwhile:

```bash
curl -s "$METABASE_URL/api/health"
```

- `{"status":"initializing","progress":…}` — migrations running. Normal; prod
  takes longer than staging.
- `{"status":"ok"}` — up and serving.

If the revision fails its startup probe, Cloud Run keeps the previous revision
serving and the site stays up on the old version. Read the failed revision's logs
first; go to [Rollback](#rollback) only if the database was already migrated.

## 7. Verify

```bash
curl -s "$METABASE_URL/api/health"   # expect {"status":"ok"}
```

Then log in and check the things a migration would plausibly break:

1. Dashboards render, including ones with filters and custom expressions.
2. A question runs against BigQuery and returns rows — this exercises the
   database connection and query processor, not just the app metadata.
3. Collections and permissions look right, and a non-admin account sees what it
   should.
4. Admin → Troubleshooting shows the version you deployed.

Do all of this on staging before touching production, and leave enough time that
someone would have noticed a problem — a day is reasonable for a minor-version
jump, less for a patch.

## 8. Production

Repeat steps 0 and 3–7 with the production block. Nothing else changes: the image
is already built and published, since both tags came from the same merge.

Prefer a low-traffic window. The outage itself is brief — the old revision serves
until the new one passes its startup probe — but the migration is the risky part
and you want to be watching when it runs.

______________________________________________________________________

## Rollback

Traffic never moves to a revision that failed its startup probe, so the site
stays up throughout. **Restore is the last resort, not the first move** — which
case you are in depends on how far migrations got, so read the logs first.

### The database was never migrated

Metabase died before reaching Liquibase — failed entrypoint, crash, probe timeout
during JVM startup. Nothing to restore; diagnose, fix, redeploy. If you deployed
by image reference, put back the one from step 3:

```bash
gcloud run services update "$RUN_SERVICE" \
  --image="<previous image from step 3>" \
  --region="$REGION" --project="$PROJECT_ID"
```

### Migrations were interrupted partway

**Do not restore.** Liquibase is resumable: each changeset commits in its own
transaction and is recorded in `databasechangelog`, so re-running picks up where
it stopped. Restoring discards correctly-applied work and puts you back at the
start of a migration you already know is slow.

Connect to the database (step 6 of [`metabase-restore.md`](metabase-restore.md)
covers the Cloud SQL Auth Proxy) and check:

```sql
SELECT * FROM databasechangeloglock;
SELECT id, filename, dateexecuted, orderexecuted
  FROM databasechangelog ORDER BY orderexecuted DESC LIMIT 10;
```

If `locked` is true and no container is running, clear it:

```sql
UPDATE databasechangeloglock
   SET locked = false, lockgranted = null, lockedby = null
 WHERE id = 1;
```

Then redeploy and let the migration finish. Widen the startup probe budget first
(see step 6) if that is what killed it, or you will land here again.

### Migrations completed, but the app is broken

**This is the case that needs a restore.** The schema is now the new version's
and the old Metabase will not run against it, so reverting the image alone leaves
you worse off. Restore the step 4 backup, *then* redeploy the old image —
**Path A** of [`metabase-restore.md`](metabase-restore.md) covers the sequence.

### Afterwards

Revert the Dockerfile pin on `main`, so the next deploy doesn't silently re-apply
the upgrade. **If the upgrade shipped via `terraform-apply`** (a `.tf` change
rather than a `gcloud run services update` — see step 5), rolling back the
service means reverting that commit, not redeploying a digest: the next apply
would otherwise put the change straight back.

## Notes

- **Nothing here happens automatically.** Merging a version bump publishes the
  image but does not deploy it: `terraform-apply` only triggers on
  `iac/**/*.tf`, and the image string in `service.tf` is an unchanging mutable
  tag, so Terraform sees no diff and creates no revision. Step 5 is what actually
  ships an upgrade. See
  [issue #4928](https://github.com/cal-itp/data-infra/issues/4928) for the
  discussion about formalizing this further.
- Because the deploy is manual and the tag is mutable, **the running version can
  lag `main`**, and by a long way — on 2026-08-12 staging was still serving an
  image built on 2026-05-29. Step 3's digest check is how you confirm what is
  actually serving.
- **Every deployment must set `CLOUD_SQL_INSTANCE_CONNECTION_NAME`.**
  `entrypoint.sh` falls back to enumerating `/cloudsql/`, which never works on
  Cloud Run — the socket is connectable but the directory is not listable, so the
  container exits 1. Both services set it in `service.tf`; new ones need it too.
- **Codify emergency Cloud Armor rules before relying on them.** `rule` blocks are
  authoritative with no `ignore_changes`, so a rule added via `gcloud` is deleted
  by the next apply — including the one shipping an upgrade. The policy and the
  service are independent resources applied in parallel, so a mitigation can be
  removed while the service update fails and leaves the old version serving.
- The OSS (`v0.x`) and Enterprise (`v1.x`) images share a base layout (Alpine,
  `/app/run_metabase.sh` entrypoint, same `JAVA_HOME`), so the `Dockerfile`'s
  `socat` layer and [`entrypoint.sh`](../../services/metabase/entrypoint.sh)
  carry across the OSS → Enterprise cutover unchanged. The Enterprise image
  additionally needs a license token supplied from Secret Manager, which is a
  `service.tf` change not covered here.
