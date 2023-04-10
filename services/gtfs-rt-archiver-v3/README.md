# gtfs-rt-archiver-v3

This is the third iteration of our GTFS RT downloader aka archiver.

## Architecture and frameworks/tools

### Huey
[huey](https://github.com/coleifer/huey) is a minimal/lightweight task queue library that we use to enqueue tasks for asynchronous/parallel execution by workers.

### Redis
Currently we use [Redis](https://github.com/redis/redis) as the storage backend
for huey. We deploy a single Redis instance per environment namespace
(e.g. `gtfs-rt-v3`, `gtfs-rt-v3-test`) with _no disk space_ and _no horizontal scaling_; we do not care about persistence because only fresh fetch tasks are relevant anyways.
In addition, the RT archiver relies on having low I/O latency with Redis to
minimize the latency of fetch starts. Due to these considerations, these Redis
instances should **NOT** be used for any other applications.


### Deployed pods
The actual archiver application is composed of three pieces.
* A ticker pod that creates fetch tasks every 20 seconds, based on the latest download configurations artifact present in GCS
  * Checks for new configurations every 5 minutes
  * Fetches are enqueued as Huey tasks
* A redis instance tasks are enqueued to and dequeued from
* 1-N consumer pods that executed enqueued fetch tasks, making HTTP requests and saving the raw responses (and metadata such as headers) to GCS
  * Each consumer pod runs some number of worker threads
  * As of 2023-04-10, the production archiver has 6 consumer pods each managing 24 worker threads

## Operations/maintenance

### Metrics
We've created a [Grafana dashboard](https://monitoring.calitp.org/d/AqZT_PA4k/gtfs-rt-archiver) to display the [metrics](https://github.com/cal-itp/data-infra/blob/main/services/gtfs-rt-archiver-v3/gtfs_rt_archiver_v3/metrics.py) for this application, based on our desired goals of

There are two important alerts defined in Grafana based on these metrics.
* [Minimum task successes](https://monitoring.calitp.org/alerting/grafana/nrbFSw0Vz/view)
* [Expiring tasks](https://monitoring.calitp.org/alerting/grafana/O595SQA4k/view)

Both of these tasks can fire if the archiver is only partially degraded, but the first alert is our best catch-all detection mechanism for any downtime. There are other potential issues (e.g. outdated download configs) that are flagged in the dashboard but do not currently have configured alerts.

### Error reporting
We log errors and exceptions (both caught and uncaught) to our [Sentry instance](https://sentry.calitp.org/) via the [Python SDK for Sentry](https://github.com/getsentry/sentry-python). Common problems include:
* Failure to connect to redis following a node upgrade; this is typicall fixed by [restarting the archiver](#restarting-the-archiver).
* RTFetchException, a custom class specific to failures during feed download; these can be provider-side (i.e. the agency/vendor) or consumer-side (i.e. us) and are usually fixed (if possible) by [changing download configurations](#fixing-download-configurations). Common examples (and HTTP error code if relevant) include:
  * Missing or invalid authentication (401/403)
  * Changed URLs (404)
  * Intermittent outages/errors (may be a ConnectionError or a 500 response)

### Restarting the archiver
Rolling restarts with kubectl use the following syntax.
```shell
kubectl rollout restart deployment.apps/<deployment> -n <namespace>
```

So for example, to restart all 3 deployments in test, you would run the following.
```shell
kubectl rollout restart deployment.apps/redis -n gtfs-rt-v3-test
kubectl rollout restart deployment.apps/gtfs-rt-archiver-ticker -n gtfs-rt-v3-test
kubectl rollout restart deployment.apps/gtfs-rt-archiver-consumer -n gtfs-rt-v3-test
```

### Deploying configuration changes
Change app vars or channel vars
`kubectl apply -k apps/overlays/gtfs-rt-archiver-v3-<env>`

### Deploying code changes
Change image tag version in kustomize
`docker push ...` or wait for github action to run in production
`kubectl apply -k apps/overlays/gtfs-rt-archiver-v3-<env>`

### Fixing download configurations
GTFS download configurations (for both Schedule and RT) are sourced from the [GTFS Dataset table](https://airtable.com/appPnJWrQ7ui4UmIl/tbl5V6Vjs4mNQgYbc) in the California Transit Airtable base. You may need to make URL or authentication adjustments in this table. This data is downloaded daily into our infrastructure and will propagate to the GTFS Schedule and RT downloads; you may execute the [Airtable download job](https://o1d2fa0877cf3fb10p-tp.appspot.com/dags/airtable_loader_v2/grid) manually after making edits to "deploy" the changes more quickly.

Another possible intervention is updating or adding authentication information in [Secret Manager](). You may create new versions . **As of 2023-04-10 the archiver does not automatically pick up new/modified secrets; you must restart the archiver for changes to take effect.**
