# GTFS-RT Archiver

This is a Cloud Run function that downloads [GTFS Realtime](https://gtfs.org/realtime/) feeds.

## Architecture

1. A Cloud Scheduler job runs every minute, which pushes a message to
1. A PubSub queue monitored by Eventarc, which triggers
1. A Cloud Workflow that fetches the latest GTFS Download Config from BigQuery, which pushes a message for each feed to
1. A PubSub queue monitored by a CloudRun Worker Pool, which spawns a number of CloudRun Jobs running
1. A Docker image containing the gtfs-rt-archiver logic.

When a gtfs-rt-archiver job recieves a new message, it builds an authenticated
HTTP request for a single VehiclePosition, ServiceAlert, or TripUpdate feed.
It then attempts to store the result along with an outcome report about the
download attempt. This provides data analysts with an easy way to tell if a
download has failed or succeeded.

## Monitoring

The gtfs-rt-archiver is monitored by Google Cloud Monitoring metrics. The north
star metric is downloads stored per minute, which has an associated alert.

## Deployment

The gtfs-rt-archiver has an associated scratch-built Docker image, which is built
for staging and deployed on every change inside pull requests. When a change makes
it to main, the production Docker image is built and deployed.
