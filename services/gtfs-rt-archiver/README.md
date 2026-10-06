# GTFS-RT Archiver

This is the [GTFS-RT](https://gtfs.org/realtime/) archiver.


## Architecture

The GTFS-RT Archiver consists of three parts running inside Google Cloud Provider:

1. Clock: Runs every minute (e.g., 00:01) and triggers the Heartbeat the next minute every 20 seconds (e.g., 00:02:00, 00:02:20, 00:02:40)
2. Heartbeat: Fetches the latest Download Configuration JSONL file from `CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG` and enqueues a message for each line
3. Service: Downloads a feed according to the Download Configuration line and stores it in Google Cloud Storage

The Clock and Heartbeat communicate via Google Pub/Sub.

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

-    max_instance_count               = 160
+    max_instance_count               = 170
     max_instance_request_concurrency = 1

     all_traffic_on_latest_revision = true
```
