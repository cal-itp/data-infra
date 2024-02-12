# gtfs-rt-archiver-v3

This is the third iteration of our [GTFS Realtime (RT)](https://gtfs.org/realtime/) downloader aka archiver.

## Architecture

> [huey](https://github.com/coleifer/huey) is a minimal/lightweight task queue library that we use to enqueue tasks for asynchronous/parallel execution by workers.

The full archiver application is composed of three pieces:

1. A ticker pod that creates fetch tasks every 20 seconds, based on the latest download configurations
   - Configurations are fetched from GCS and cached for 5 minutes; they are generated upstream by [generate_gtfs_download_configs](../../airflow/dags/airtable_loader_v2/generate_gtfs_download_configs.py)
   - Fetches are enqueued as Huey tasks
2. A Redis instance holding the Huey queue
   - We deploy a single instance per environment namespace
     (e.g. `gtfs-rt-v3`, `gtfs-rt-v3-test`) with _no disk space_ and _no horizontal scaling_; we do not care about persistence because only fresh fetch tasks are relevant anyways.
   - In addition, the RT archiver relies on having low I/O latency with Redis to
     minimize the latency of fetch starts. Due to these considerations, these Redis
     instances should **NOT** be used for any other applications.
3. Some number (greater than 1) of consumer pods that execute enqueued fetch tasks, making HTTP requests and saving the raw responses (and metadata such as headers) to GCS
   - Each consumer pod runs some number of worker threads
   - As of 2023-04-10, the production archiver has 6 consumer pods each managing 24 worker threads

These deployments are defined in the [relevant kubernetes manifests](../../kubernetes/apps/manifests/gtfs-rt-archiver-v3) and overlaid with kustomize per-environment (e.g. [gtfs-rt-archiver-v3-test](../../kubernetes/apps/overlays/gtfs-rt-archiver-v3-test)).

## Observability

### Metrics

We've created a [Grafana dashboard](https://monitoring.calitp.org/d/AqZT_PA4k/gtfs-rt-archiver) to display the [metrics](./gtfs_rt_archiver_v3/metrics.py) for this application, based on our desired goals of capturing data to the fullest extent possible and being able to track 20-second update frequencies in the feeds. Counts of task successes is our overall sign of health (i.e. we are capturing enough data) while other metrics such as task delay or download time are useful for identifying bottlenecks or the need for increased resources.

### Alerts

There are two important alerts defined in Grafana based on these metrics.

- [Minimum task successes](https://monitoring.calitp.org/alerting/grafana/nrbFSw0Vz/view)
- [Expiring tasks](https://monitoring.calitp.org/alerting/grafana/O595SQA4k/view)

Both of these tasks can fire if the archiver is only partially degraded, but the first alert is our best catch-all detection mechanism for any downtime. There are other potential issues (e.g. outdated download configs) that are flagged in the dashboard but do not currently have configured alerts.

### Error reporting

We log errors and exceptions (both caught and uncaught) to our [Sentry instance](https://sentry.calitp.org/) via the [Python SDK for Sentry](https://github.com/getsentry/sentry-python). Common problems include:

- Failure to connect to Redis following a node upgrade; this is typically fixed by [restarting the archiver](#restarting-the-archiver).
- `RTFetchException`, a custom class specific to failures during feed download; these can be provider-side (i.e. the agency/vendor) or consumer-side (i.e. us) and are usually fixed (if possible) by [changing download configurations](#changing-download-configurations). Common examples (and HTTP error code if relevant) include:
  - Missing or invalid authentication (401/403)
  - Changed URLs (404)
  - Intermittent outages/errors (may be a ConnectionError or a 500 response)

## Operations/maintenance

> You must have [installed and authenticated kubectl](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl) before executing commands (you will need GKE permissions in GCP for this). It's also useful to set your default cluster to our data-infra-apps cluster.
>
> These `kubectl` commands assume your shell is in the `kubernetes` directory, but you could run them from root and just prepend `kubernetes/` to the file paths.

### Restarting the archiver

Rolling restarts with `kubectl` use the following syntax.

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

Environment-agnostic configurations live in [app vars](../../kubernetes/apps/manifests/gtfs-rt-archiver-v3/archiver-app-vars.yaml) while environment-specific configurations live in [channel vars](../../kubernetes/apps/overlays/gtfs-rt-archiver-v3-test/archiver-channel-vars.yaml). You can edit these files and deploy the changes with `kubectl`.

```
kubectl apply -k apps/overlays/gtfs-rt-archiver-v3-<env>
```

For example, you can apply the configmap values in [test](../../kubernetes/apps/overlays/gtfs-rt-archiver-v3-test/archiver-channel-vars.yaml) with the following.

```
kubectl apply -k apps/overlays/gtfs-rt-archiver-v3-test
```

Running `apply` will also deploy the archiver from scratch if it is not deployed yet, as long as the proper namespace exists.

### Deploying code changes

Code changes require building and pushing a new Docker image, as well as applying `kubectl` changes to point the deployment at the new image.

1. Make code changes and increment version in `pyproject.toml`
   1. Ex. `poetry version 2023.4.10`
2. Change image tag version in the environments `kustomization.yaml`.
   1. Ex. change the value of `newTag` to '`2023.4.10'`
3. `docker build ... & docker push ...` (*from within the archiver directory*) or wait for [build-gtfs-rt-archiver-v3-image](../../.github/workflows/build-gtfs-rt-archiver-v3-image.yml) GitHub Action to run after merge to main
   1. Ex. `docker build -t ghcr.io/cal-itp/data-infra/gtfs-rt-archiver-v3:2023.4.10 . && docker push ghcr.io/cal-itp/data-infra/gtfs-rt-archiver-v3:2023.4.10`
   2. To push from your local machine, you must have [authenticated to ghcr.io](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry)
4. Finally, apply changes using `kubectl` as described above.
   1. Currently, the image is built/pushed on merges to main but the Kubernetes manifests are not applied.

### Changing download configurations

GTFS download configurations (for both Schedule and RT) are sourced from the [GTFS Dataset table](https://airtable.com/appPnJWrQ7ui4UmIl/tbl5V6Vjs4mNQgYbc) in the California Transit Airtable base, and we have [specific documentation](https://docs.google.com/document/d/1IO8x9-31LjwmlBDH0Jri-uWI7Zygi_IPc9nqd7FPEQM/edit#heading=h.b2yta6yeugar) for modifying the table. (Both of these Airtable links require authentication/access to Airtable.) You may need to make URL or authentication adjustments in this table. This data is downloaded daily into our infrastructure and will propagate to the GTFS Schedule and RT downloads; you may execute the [Airtable download job](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/airtable_loader_v2/grid) manually after making edits to "deploy" the changes more quickly.

Another possible intervention is updating or adding authentication information in [Secret Manager](https://console.cloud.google.com/security/secret-manager). You may create new versions of existing secrets, or add entirely new secrets. Secrets must be tagged with `gtfs_rt: true` to be loaded as secrets in the archiver; secrets are refreshed every 5 minutes by the ticker.
