# GTFS-RT Archiver

This is the [GTFS-RT](https://gtfs.org/realtime/) archiver.


## Architecture

The GTFS-RT Archiver consists of three parts running inside Google Cloud Provider:

1. Scheduler: Runs every minute and triggers the Workflow
2. Workflow: Fetches the latest Download Configuration and enqueues a message for each line
3. Cloud Run Worker Pool: Downloads a feed according to the Download Configuration line and stores it in Google Cloud Storage


## Deployment

The Workflow is deployed via Terraform from the `gtfs-rt-archiver-heartbeat.yaml`.
The Cloud Run Worker Pool is deployed from source to a bucket via Terraform.


## Development

To set up your local development environment:

1. Copy `.env.example` to `.env` and fill in values
2. Run `uv sync`
3. To run tests, run `uv run pytest`
4. If you introduce new dependencies, add them to `requirements.txt`
