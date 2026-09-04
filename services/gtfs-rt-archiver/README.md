# GTFS-RT Archiver

This is the [GTFS-RT](https://gtfs.org/realtime/) archiver.


## Architecture

The GTFS-RT Archiver consists of three parts running inside Google Cloud Provider:

1. Clock: Runs every minute (e.g., 00:01) and triggers the Heartbeat the next minute every 20 seconds (e.g., 00:02:00, 00:02:20, 00:02:40)
2. Heartbeat: Fetches the latest Download Configuration JSONL file from `CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG` and enqueues a message for each line
3. Service: Downloads a feed according to the Download Configuration line and stores it in Google Cloud Storage

The Clock and Heartbeat communicate via Google Pub/Sub.

A second, optional copy of this same pipeline — the **high-frequency lane** — can be
switched on to archive a named handful of feeds at a faster cadence for a study. It
runs the same code from the same source zip and differs only in configuration: its
own clock (`clock_high_frequency.yaml`), its own topics and functions, and its own
destination bucket. It is off unless a cohort is configured, and the feeds in a
cohort keep running on the standard 20-second clock as well. See the runbook below.

Google Cloud Provider APIs required:

* Workflows
* Cloud Run
* Eventarc


## Deployment

The Clock is a Google Workflow created via Terraform according to `clock.yaml`.
The Heartbeat and Service are deployed to Cloud Run Services, and the source is shared between them.
The code is copied from this directory, compressed into a zip file, and uploaded to a bucket via Terraform.


## Development

To set up your local development environment:

1. Copy `.env.example` to `.env` and fill in values (for now, the staging buckets and topic)
2. Run `uv sync`
3. To run tests, run `uv run pytest`
4. If you introduce new dependencies, add them to `requirements.txt`


## Runbook: Adding a Custom Certificate

From time to time, GTFS-RT feeds are served with a self-signed certificate.
You can tell this is happening when this error appears in the logs:

```
SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate (_ssl.c:1016)'))
```

The impact is that feeds served by this host are not able to be downloaded.

The solution is certificate pinning, which will periodically fail due to certificate expiration.
To capture the custom certificate chain for this domain, use the following script and change `example.com` to the domain in question:

```bash
$ echo | openssl s_client -showcerts -connect example.com:443 2>/dev/null | openssl x509 -outform PEM > certificates/example.com.pem
```

Once you check this certificate in, the next request should succeed.

> Security Note: when a custom certificate is provided, hostname verification is disabled.


## Runbook: Hitting an Autoscaling Limit

From time to time, the GTFS-RT archiver Cloud Run service runs out of capacity.
You can tell this is happening when this warning appears in the logs:

```
HTTP Status 429: The request was aborted because there was no available instance. Additional troubleshooting documentation can be found at: https://cloud.google.com/run/docs/troubleshooting#abort-request
```

The impact is that some feeds downloads may be scheduled after a delay, potentially changing the results of the GTFS-RT archiving process.

The solution is to increase the maximum instances for the `gtfs-rt-archiver` service, usually by a small number:

```diff
+++ b/iac/cal-itp-data-infra/gtfs-rt-archiver/us/service.tf
@@ -87,7 +87,7 @@ resource "google_cloudfunctions2_function" "gtfs-rt-archiver" {
     available_memory = "256M"
     ingress_settings = "ALLOW_INTERNAL_ONLY"

-    max_instance_count               = 300
+    max_instance_count               = 310
     max_instance_request_concurrency = 1

     all_traffic_on_latest_revision = true
```

Note that the high-frequency lane, if one is running, has its own separate function
and therefore its own instance pool — it cannot consume capacity from this one, and
raising this value does not raise its ceiling.


## Runbook: Running a High-Frequency Feed Cohort

For a time-boxed study — for example transit signal priority work needing ~3-second
vehicle position samples for one or two agencies — a named cohort of feeds can be
archived on a faster clock than the standard 20 seconds.

### Before you start

**Get the agency's agreement, and record it in the pull request.** A 3-second poll is
roughly a seven-fold increase in request rate against someone else's server. The
archiver has no rate-limit handling, backoff, or circuit breaker, and it presents a
browser User-Agent. If an agency rate-limits or blocks us in response, we lose that
feed for the *standard* pipeline too — a permanent hole in their history caused by a
temporary experiment.

The cohort is capped at two feeds and the cadence floor is 3 seconds. Both limits are
enforced by Terraform variable validation, and the cohort size is enforced again in
the heartbeat, which publishes nothing at all rather than truncating if the cap is
exceeded.

### Turning it on

Edit `high_frequency_cohort` in `iac/cal-itp-data-infra/gtfs-rt-archiver/us/variables.tf`
and merge to `main`:

```hcl
variable "high_frequency_cohort" {
  type    = list(string)
  default = ["Big Blue Bus VehiclePositions"]
}
```

Names match the `name` field of the download config — the same value shown in the
GTFS datasets table — compared case-insensitively and tolerant of extra whitespace. A
name that matches nothing logs a warning and archives nothing, so check the logs after
enabling rather than assuming silence means success.

The value lives in `variables.tf` rather than a `terraform.tfvars` on purpose: CI picks
apply targets with a `**/*.tf` glob, so a tfvars-only change would produce no plan and
no apply, and the toggle would appear to work while doing nothing.

For the first hour, consider setting the Cloud Scheduler payload to `{"limit": 1}` so
only a single feed runs; the clock forwards that through to the heartbeat and no
redeploy is needed.

### Where the data goes

`gs://calitp-gtfs-rt-raw-high-frequency`, in the same partition layout as the standard
bucket. It is deliberately separate: cadence is not recorded anywhere downstream, so
mixing 3-second samples into the standard bucket would shift the published GTFS quality
scores for that agency — `rt_20sec_vp` in particular measures how stale a feed was when
we scraped it, which polling faster improves without the producer changing anything.

Objects accumulate at 20 per minute per feed (1,200/hour, ~28,800/day). The bucket has
a 180-day delete lifecycle rule and no retention policy. Check results with a pinned
prefix and a limit — never a recursive listing:

```bash
gcloud storage ls --limit=50 \
  'gs://calitp-gtfs-rt-raw-high-frequency/vehicle_positions/dt=<date>/hour=<hour>/'
```

### Turning it off

Set `high_frequency_cohort` back to `[]` and merge. Every resource in the lane is
`count`-gated, so the scheduler, workflow, topics, and both functions are destroyed;
the bucket and the collected data remain.

**To stop it immediately**, pause the scheduler out of band:

```bash
gcloud scheduler jobs pause gtfs-rt-archiver-high-frequency-clock \
  --location=us-west2 --project=cal-itp-data-infra
```

Production `terraform apply` is not auto-approved, so the Terraform route is a
pull-request round trip. Follow up with that PR afterwards, because a later apply will
undo the pause.
