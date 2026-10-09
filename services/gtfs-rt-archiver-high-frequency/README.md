# GTFS-RT Archiver: High-Frequency Lane

A copy of the [GTFS-RT archiver](../gtfs-rt-archiver/README.md) that archives a small,
named cohort of feeds on a faster clock (3 seconds by default, instead of 20) for a
time-boxed study, such as transit signal priority work that needs dense vehicle
position samples for one or two agencies (issue #5566).

It is deliberately a separate copy of the code. Nothing in this directory or in
`iac/*/gtfs-rt-archiver/us/high_frequency.tf` changes what the standard archiver
runs, and the cohort feeds keep running on the standard 20-second clock throughout
the study, so the published RT dataset never has a gap for a study agency.


## Architecture

Same three parts as the standard archiver, with its own copy of each:

1. **Clock** (`clock_high_frequency.yaml`): a Cloud Workflow triggered every minute by
   Cloud Scheduler. It publishes one tick per cadence for the following minute (20
   ticks at 3s), each stamped with a grid-aligned `batch_at`.
2. **Heartbeat** (`process_clock_event`): reads the download config, keeps only the
   feeds named in `CALITP_GTFS_RT_HIGH_FREQUENCY_COHORT`, and enqueues one message per
   feed per tick.
3. **Service** (`process_heartbeat_event`): downloads the feed and writes it to the
   high-frequency bucket, partitioned by `batch_at` so ticks never collide. Writes use
   `if_generation_match=0` (`CALITP_GTFS_RT_FAIL_ON_OVERWRITE`), so a colliding path is
   logged as a failure instead of silently overwriting data.

| | staging | production |
|---|---|---|
| Terraform | `iac/cal-itp-data-infra-staging/gtfs-rt-archiver/us/high_frequency.tf` | `iac/cal-itp-data-infra/gtfs-rt-archiver/us/high_frequency.tf` |
| Toggle | `high_frequency_cohort` in that directory's `variables.tf` | same |
| Bucket | `gs://calitp-staging-gtfs-rt-raw-high-frequency` | `gs://calitp-gtfs-rt-raw-high-frequency` |
| Scheduler job | `gtfs-rt-archiver-staging-high-frequency-clock` | `gtfs-rt-archiver-high-frequency-clock` |
| Applied when | merged to `staging/official` (auto-approved) | merged to `main` (manual approval) |

Every resource except the bucket is `count`-gated on the cohort being non-empty, so
when no study is running the lane does not exist and costs nothing.

### Guardrails

- The cohort is capped at **2 feeds** and the cadence floor is **3 seconds**, enforced
  by Terraform variable validation.
- The archiver function has its own instance pool (`max_instance_count = 5`), so a
  misconfigured cohort can only slow the study, never take capacity from the standard
  archiver.
- `REQUEST_READ_TIMEOUT` is `cadence - 1`, so slow responses don't stack up against an
  agency's server.
- Pub/Sub retries are disabled, since a late tick has no value at this cadence.


## Starting an experiment

### 1. Get the agency's agreement

A 3-second poll is about a seven-fold increase in request rate against someone else's
server. The archiver has no rate-limit handling, backoff, or circuit breaker. If an
agency rate-limits or blocks us, we lose that feed for the **standard** pipeline too.
Get agreement before you start, and link it in the pull request.

### 2. Pick the feeds

Cohort entries are download config `name` values (the same names as in the GTFS
datasets table), for example `"Big Blue Bus VehiclePositions"`. Matching ignores case
and extra whitespace. Each feed type is a separate download config, so list the
`VehiclePositions` entry explicitly if that is what the study needs.

### 3. Soak in staging

Set the cohort in `iac/cal-itp-data-infra-staging/gtfs-rt-archiver/us/variables.tf`:

```hcl
variable "high_frequency_cohort" {
  ...
  default = ["Big Blue Bus VehiclePositions"]
  ...
}
```

Open a pull request against `staging/official`, review the Terraform plan comment
(it should only *create* `*-high-frequency*` resources, and nothing in `service.tf` or
`workflow.tf` should change), then merge it. Change the value in `variables.tf`, not
in a `terraform.tfvars`: CI picks apply targets by changed `*.tf` files, so a
tfvars-only change would plan and apply nothing.

Then check the results (see [Checking that it works](#checking-that-it-works)).

### 4. Enable in production

Make the same change in `iac/cal-itp-data-infra/gtfs-rt-archiver/us/variables.tf`,
open a pull request against `main`, check the plan, and merge. The production apply
waits for manual approval.

**Optional canary:** to run only one feed for the first hour, set the scheduler
payload to `{"limit": 1}`. The clock passes it through to the heartbeat, so no
redeploy is needed:

```bash
gcloud scheduler jobs update pubsub gtfs-rt-archiver-high-frequency-clock \
  --location=us-west2 --project=cal-itp-data-infra \
  --message-body='{"limit": 1}'
```

Set it back with `--message-body='{"limit": null}'`. This is an out-of-band change, so
the next Terraform apply also resets it to `null`.


## Checking that it works

**Logs first.** In Cloud Logging, filter on the `gtfs-rt-archiver-high-frequency` and
`gtfs-rt-archiver-high-frequency-heartbeat` functions (prefixed with `-staging-` in
staging), and look for:

- `High-frequency cohort matched no download config`: a cohort name is wrong. The
  lane archives nothing for that name, so a quiet log doesn't mean it's working.
- `PreconditionFailed` / `412`: two writes went to the same object path. Expected
  never; investigate the clock if it shows up.
- Timeouts or `429`s from the agency: consider ending the experiment.

**GCS: list one pinned prefix with a limit, never recursively.** The lane writes 20
objects per minute per feed (about 28,800 a day), and object count drives cost:

```bash
gcloud storage ls --limit=50 \
  'gs://calitp-gtfs-rt-raw-high-frequency/vehicle_positions/dt=2026-10-06/hour=2026-10-06T17:00:00+00:00/'
```

Paths use the same layout as the standard archiver:
`<feed_type>/dt=<date>/hour=<hour>/ts=<batch_at>/base64_url=<url>/<file>`.

The data is kept out of the standard bucket on purpose. Cadence isn't recorded
downstream, so 3-second samples would skew that agency's published GTFS-RT quality
metrics (for example `rt_20sec_vp`).


## Ending an experiment

### Normal shutdown

Set `high_frequency_cohort` back to `[]` in the same `variables.tf` (staging and/or
production) and merge through the same branch as above. Terraform then destroys the
scheduler, workflow, Eventarc trigger, topics, both functions and the source zip.
Review the plan: the only deletions should be `*-high-frequency*` resources.

The **bucket and its data are kept.** Objects are deleted automatically 365 days
after they were written. Before that, export or copy whatever the study needs.

### Stopping immediately

A production apply needs a pull request and manual approval. To stop polling the
agency right away, pause the scheduler first:

```bash
gcloud scheduler jobs pause gtfs-rt-archiver-high-frequency-clock \
  --location=us-west2 --project=cal-itp-data-infra
```

The current minute's ticks (already queued by the workflow) still run; nothing starts
after that. Then follow up with the `[]` pull request: a later apply un-pauses the job
for as long as the cohort is still set.

### Deleting the data early

If the study data must be removed before the lifecycle rule does it, delete by prefix
after confirming the scope and object count with the team. Bulk deletes are billed
per object.


## Development

This directory started as a copy of `services/gtfs-rt-archiver` and is maintained
separately. Fixes to the standard archiver (for example new pinned certificates in
`certificates/`) are **not** picked up automatically; port them here if the cohort
needs them.

1. Copy `.env.example` to `.env` and fill in values (staging buckets and topics)
2. `uv sync`
3. `uv run pytest`
4. If you add dependencies, also add them to `requirements.txt` (that's what the Cloud
   Function installs)

A change to any file in this directory redeploys the high-frequency functions: CI
plans and applies the `gtfs-rt-archiver/us` Terraform directories when it sees it.
That only has an effect while a cohort is set, because the source zip and functions
don't exist otherwise.
