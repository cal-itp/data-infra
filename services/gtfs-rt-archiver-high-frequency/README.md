# GTFS-RT Archiver: High-Frequency Lane

A copy of the [GTFS-RT archiver](../gtfs-rt-archiver/README.md) that archives a small
set of feeds on a faster clock (3 seconds by default, instead of 20) for a time-boxed
study, such as transit signal priority work that needs dense vehicle position samples
for a few agencies (issue #5566).

It is deliberately a separate deployment. Nothing in this directory or in
`iac/*/gtfs-rt-archiver/us/high_frequency.tf` changes what the standard archiver
runs, and the study feeds keep running on the standard 20-second clock throughout the
study, so the published RT dataset never has a gap for a study agency.

The Python code is the standard archiver's code with **one change**:
`Configuration.ts()` in `gtfs_rt_archiver/configuration.py` keeps the full publish
time instead of rounding it down to 20 seconds. Keeping the rest identical makes this
lane a faithful test bed, and lets it be folded back into the standard service later.


## Architecture

The same three parts as the standard archiver, with its own copy of each:

1. **Clock** (`clock_high_frequency.yaml`): a Cloud Workflow triggered every minute by
   Cloud Scheduler. It publishes one tick per cadence for the following minute (20
   ticks at 3s). Each tick sleeps until its scheduled time before publishing, so ticks
   don't drift.
2. **Heartbeat** (`process_clock_event`): reads the newest download config from the
   lane's **config bucket** and enqueues one message per feed per tick, exactly as the
   standard heartbeat does with the Airflow-generated config.
3. **Service** (`process_heartbeat_event`): downloads the feed and writes it to the
   high-frequency data bucket. The `ts=` partition is the full-precision publish time
   of that feed's message, so every tick gets its own object path.

Which feeds are archived is decided entirely by the config file in the config bucket,
not by Terraform. That means feeds can be changed without a pull request, and they
don't have to be in Airtable.

The heartbeat only reads configs dated within the last 5 days. The standard archiver
gets a new dated config from Airflow every day; this lane's config is maintained by
hand, so a **daily refresh workflow** (`config_refresh.yaml`, 04:00 Pacific) copies the
hand-edited `source/configs.jsonl.gz` into that day's `gtfs_download_configs/dt=.../`
path.

| | staging | production |
|---|---|---|
| Terraform | `iac/cal-itp-data-infra-staging/gtfs-rt-archiver/us/high_frequency.tf` | `iac/cal-itp-data-infra/gtfs-rt-archiver/us/high_frequency.tf` |
| On/off switch | `high_frequency_enabled` in that directory's `variables.tf` | same |
| Config bucket | `gs://calitp-staging-gtfs-rt-high-frequency-config` | `gs://calitp-gtfs-rt-high-frequency-config` |
| Data bucket | `gs://calitp-staging-gtfs-rt-raw-high-frequency` | `gs://calitp-gtfs-rt-raw-high-frequency` |
| Clock scheduler job | `gtfs-rt-archiver-staging-high-frequency-clock` | `gtfs-rt-archiver-high-frequency-clock` |
| Config refresh workflow | `gtfs-rt-archiver-staging-high-frequency-config-refresh` | `gtfs-rt-archiver-high-frequency-config-refresh` |
| Applied when | pushed to any `staging/**` branch (auto-approved), or merged to `main` | merged to `main` (manual approval) |

Every resource except the two buckets only exists while `high_frequency_enabled` is
`true`, so when no study is running the lane costs nothing. The buckets are kept so
the config and the collected data survive turning the lane off and on.

### Guardrails

- **At most 5 feeds in the config.** This is a rule, not a check: nothing in code or
  Terraform counts the lines, so review the file before uploading it. See
  [Cost](#cost) before adding feeds.
- The archiver function has its own instance pool (`max_instance_count = 10`, twice the
  feed cap). A config with too many feeds can only slow the study down, never take
  capacity from the standard archiver or run up compute.
- The cadence floor is **3 seconds**, enforced by Terraform variable validation.
- `REQUEST_READ_TIMEOUT` is `cadence - 1`, so slow responses don't stack up against an
  agency's server.
- Pub/Sub retries are disabled, since a late tick has no value at this cadence.
- The config bucket has object versioning, so every change to the feed list is kept.


## Cost

Rough monthly estimates at the default 3-second cadence, from approximate GCP list
prices for `us-west2`. Treat them as an order of magnitude and check the billing report
after the first week of a study.

### Per feed

Each feed is fetched 20 times a minute: 28,800 times a day, about 864,000 a month.

| Item | Basis | Per feed per month |
|---|---|---|
| GCS writes | 864,000 Class A operations at $0.005 per 1,000 | ~$4.30 |
| Archiver compute | 864,000 requests at 0.167 vCPU + 256 MB, assuming ~1 s each | ~$4.00 |
| Archiver requests | $0.40 per million | ~$0.35 |
| Storage, typical feed | ~6 KB per file, ~5 GB added a month | ~$0.10 the first month, ~$2.15 by month 18, ~$2.90 at most (730 days kept) |
| Storage, largest feed | ~186 KB per file, ~160 GB added a month | ~$3.70 the first month, ~$66 by month 18, ~$88 at most (730 days kept) |
| **Total, typical feed** | | **~$9, rising to ~$11 by month 18** |
| **Total, largest feed** | | **~$12, rising to ~$75 by month 18** |

File sizes come from one 20-second partition of the standard archiver's production
bucket on 2026-10-22: 161 vehicle positions files, mean 5.9 KB, median 1.1 KB, 90th
percentile 8.3 KB, largest 186 KB. Storage keeps growing for the first 730 days and then
levels off, because the lifecycle rule deletes the oldest files; month 18 is the planned
length of the study. Look up the feed's own file size before adding it, since that is
what decides whether it is a $10 feed or a $75 one.

Not included: Cloud Logging and Pub/Sub, expected to be under about $1 per feed per
month.

### Fixed, while the lane is on

These don't depend on the number of feeds and stop when `high_frequency_enabled` is
set back to `false`.

| Item | Basis | Per month |
|---|---|---|
| Clock workflow | ~64 steps per execution, 1,440 executions a day, about 2.8M steps at $0.01 per 1,000 | ~$28 |
| Heartbeat | One download-config listing per tick (864,000 Class A operations), plus one always-on instance | ~$8 |
| Config refresh | One short workflow run and one object copy a day | under $0.01 |
| **Total** | | **~$36** |

For example, 5 typical feeds come to about $36 + 5 × $9 = **$81 a month** at the start,
rising to about $36 + 5 × $11 = **$91 a month** by month 18.


## The config file

`source/configs.jsonl.gz` in the config bucket: gzip-compressed JSON Lines, one line per
feed, in the same format Airflow writes for the standard archiver:

```json
{"extracted_at":"2026-10-27T03:00:00+00:00","name":"LA DOT VehiclePositions","url":"https://ladotbus.com/gtfs-rt/vehiclepositions","feed_type":"vehicle_positions","schedule_url_for_validation":"https://ladotbus.com/gtfs","auth_query_params":{},"auth_headers":{},"computed":false}
```

- `auth_headers` and `auth_query_params` map a header or parameter name to the **name of
  a Secret Manager secret**, never the secret value, e.g.
  `"auth_headers":{"x-api-key":"example-agency-api-key"}`. The archiver service account
  must be able to read that secret.
- For a feed that is already in Airtable, copy its line from the standard archiver's
  config for today rather than writing it by hand. That is one small object:

  ```bash
  LATEST=$(gcloud storage ls "gs://calitp-gtfs-download-config/gtfs_download_configs/dt=$(date -u +%F)/**" | sort | tail -1)
  gcloud storage cat "$LATEST" | gunzip \
    | jq -c 'select(.name == "LA DOT VehiclePositions")' >> configs.jsonl
  ```

  (Staging's equivalent bucket is `calitp-staging-gtfs-download-config`.)
- For a feed that isn't in Airtable, write the line by hand. `extracted_at` can be the
  date you wrote it, and `schedule_url_for_validation` is the agency's GTFS Schedule
  zip.


## Starting an experiment

### 1. Get the agency's agreement

A 3-second poll is about a seven-fold increase in request rate against someone else's
server. The archiver has no rate-limit handling, backoff, or circuit breaker. If an
agency rate-limits or blocks us, we lose that feed for the **standard** pipeline too.

Get agreement before adding a feed, and record it on the issue (#5566 or the study's
own issue), since feed changes no longer go through a pull request.

### 2. Upload the config

Build `configs.jsonl` (see [The config file](#the-config-file)), check it has at most 5
lines, then upload it to the config bucket **twice**: once as the source the daily
refresh copies, and once into today's dated path so the heartbeat can read it straight
away.

```bash
BUCKET=gs://calitp-staging-gtfs-rt-high-frequency-config   # or the production bucket
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

gzip -kf configs.jsonl
gcloud storage cp configs.jsonl.gz "$BUCKET/source/configs.jsonl.gz"
gcloud storage cp configs.jsonl.gz "$BUCKET/gtfs_download_configs/dt=${NOW:0:10}/ts=$NOW/configs.jsonl.gz"
```

Upload the gzipped file as is. Don't use `gcloud storage cp -Z` / `--gzip-in-flight`,
which would make GCS decompress the file on download and break the heartbeat.

**Do this before turning the lane on.** With no dated config in the bucket, the
heartbeat (unchanged standard code) fails on every tick.

### 3. Soak in staging

Set `high_frequency_enabled` to `true` in
`iac/cal-itp-data-infra-staging/gtfs-rt-archiver/us/variables.tf`:

```hcl
variable "high_frequency_enabled" {
  ...
  default     = true
}
```

Commit that on a `staging/<name>` branch and push it. Any push to a `staging/**` branch
auto-applies the staging Terraform it changed. Do not merge the change to `main`: it
would turn the lane on in staging for good. The plan should only *create*
`*-high-frequency*` resources, and nothing in `service.tf` or `workflow.tf` should
change. Change the value in `variables.tf`, not in a `terraform.tfvars`: CI picks apply
targets by changed `*.tf` files, so a tfvars-only change would plan and apply nothing.

Staging Terraform state is shared. Any later staging apply of the archiver directory
from a branch where `high_frequency_enabled` is `false` turns the lane off again,
including merges to `main` that touch the archiver. Keep the soak short. When it is
done, push `high_frequency_enabled = false` to the same branch.

Then check the results (see [Checking that it works](#checking-that-it-works)).

### 4. Enable in production

Upload the production config (step 2, with the production bucket), then make the same
change in `iac/cal-itp-data-infra/gtfs-rt-archiver/us/variables.tf`, open a pull request
against `main`, check the plan, and merge. The production apply waits for manual
approval.

To canary, start with a single feed in the config and add the rest once it looks right.


## Changing feeds

No pull request is needed. Edit `configs.jsonl` and repeat [step 2](#2-upload-the-config).
The change takes effect on the next minute's ticks. Record any newly added agency's
agreement on the issue first.

Every upload is kept as a previous version of `source/configs.jsonl.gz`, so the history
of feed changes can be listed with:

```bash
gcloud storage ls -a gs://calitp-gtfs-rt-high-frequency-config/source/
```


## Checking that it works

**Logs first.** In Cloud Logging, filter on the `gtfs-rt-archiver-high-frequency` and
`gtfs-rt-archiver-high-frequency-heartbeat` functions (prefixed with `-staging-` in
staging), and look for:

- Heartbeat errors such as `IndexError`: there is no config dated within the last 5
  days. Check the refresh workflow's executions, or upload the config again (step 2).
- Secret Manager errors from the archiver: an `auth_headers` / `auth_query_params`
  entry names a secret that doesn't exist or can't be read.
- Timeouts or `429`s from the agency: consider ending the experiment.

**GCS: list a few seconds at a time, never a whole hour or day.** The lane writes 20
objects per minute per feed (about 28,800 a day), and object count drives cost. A
10-second window returns about 3 objects per feed:

```bash
gcloud storage ls -l \
  'gs://calitp-gtfs-rt-raw-high-frequency/vehicle_positions/dt=2026-10-06/hour=2026-10-06T17:00:00+00:00/ts=2026-10-06T17:00:0*/**'
```

Paths use the same layout as the standard archiver:
`<feed_type>/dt=<date>/hour=<hour>/ts=<publish time>/base64_url=<url>/<file>`. Unlike the
standard archiver, `ts` keeps microseconds and is not on a 20-second grid (for example
`ts=2026-10-06T17:00:03.412000+00:00`), so it reflects when each fetch was actually
triggered.

The data is kept out of the standard bucket on purpose. Cadence isn't recorded
downstream, so 3-second samples would skew that agency's published GTFS-RT quality
metrics (for example `rt_20sec_vp`).


## Ending an experiment

### Normal shutdown

Set `high_frequency_enabled` back to `false` in the same `variables.tf` (staging and/or
production) and merge through the same branch as above. Terraform then destroys the
schedulers, workflows, Eventarc trigger, topics, both functions and the source zip.
Review the plan: the only deletions should be `*-high-frequency*` resources.

The **config and data buckets are kept.** Data objects are deleted automatically 730
days after they were written. Before that, export or copy whatever the study needs.

### Stopping immediately

A production apply needs a pull request and manual approval. To stop polling the
agency right away, pause the clock scheduler first:

```bash
gcloud scheduler jobs pause gtfs-rt-archiver-high-frequency-clock \
  --location=us-west2 --project=cal-itp-data-infra
```

The current minute's ticks (already queued by the workflow) still run; nothing starts
after that. Then follow up with the `false` pull request: a later apply un-pauses the
job for as long as the lane is still enabled.

To stop a single feed instead, remove it from the config and upload it again; that
takes effect within a minute.

### Deleting the data early

If the study data must be removed before the lifecycle rule does it, delete by prefix
after confirming the scope and object count with the team. Bulk deletes are billed
per object.


## Development

This directory started as a copy of `services/gtfs-rt-archiver` and is maintained
separately, but its Python code should stay identical to the standard archiver's except
for `Configuration.ts()`. Fixes to the standard archiver (for example new pinned
certificates in `certificates/`) are **not** picked up automatically; port them here.
To see the differences:

```bash
diff -r services/gtfs-rt-archiver/gtfs_rt_archiver services/gtfs-rt-archiver-high-frequency/gtfs_rt_archiver
```

1. Copy `.env.example` to `.env` and fill in values (staging buckets and topics)
2. `uv sync`
3. `uv run pytest`
4. If you add dependencies, also add them to `requirements.txt` (that's what the Cloud
   Function installs)

A change to any file in this directory redeploys the high-frequency functions: CI
plans and applies the `gtfs-rt-archiver/us` Terraform directories when it sees it.
That only has an effect while the lane is enabled, because the source zip and
functions don't exist otherwise.
