# GTFS-RT Archiver

This is the [GTFS-RT](https://gtfs.org/realtime/) archiver.


## Architecture

The GTFS-RT Archiver consists of three parts running inside Google Cloud Provider:

1. Clock: Runs every minute (e.g., 00:01) and triggers the Heartbeat the next minute every 20 seconds (e.g., 00:02:00, 00:02:20, 00:02:40)
2. Heartbeat: Fetches the latest Download Configuration JSONL file from `CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG` and enqueues a message for each line
3. Service: Downloads a feed according to the Download Configuration line and stores it in Google Cloud Storage

The Clock and Heartbeat communicate via Google Pub/Sub.


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

The solution is certificate pinning, which will periodically fail due to certificate expiration.
To capture the custom certificate chain for this domain, use the following script and change `example.com` to the domain in question:

```bash
$ echo | openssl s_client -showcerts -connect example.com:443 2>/dev/null | openssl x509 -outform PEM > certificates/example.com.pem
```

Once you check this certificate in, the next request should succeed.

> Security Note: when a custom certificate is provided, hostname verification is disabled.
