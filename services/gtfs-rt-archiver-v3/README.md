# gtfs-rt-archiver-v3

This is the third iteration of our [GTFS Realtime (RT)](https://gtfs.org/realtime/) downloader aka archiver.

## Architecture

> [huey](https://github.com/coleifer/huey) is a minimal/lightweight task queue library that we use to enqueue tasks for asynchronous/parallel execution by workers.

The full archiver application is composed of three pieces:

1. A ticker pod that creates fetch tasks every 20 seconds, based on the latest download configurations
   - Configurations are fetched from GCS and cached for 5 minutes; they are generated upstream by [download_parse_and_validate_gtfs](../../airflow/dags/download_parse_and_validate_gtfs.py)
   - Fetches are enqueued as Huey tasks
2. A Redis instance holding the Huey queue
   - We deploy a single instance in the `gtfs-rt-v3` namespace with _no disk space_ and _no horizontal scaling_; we do not care about persistence because only fresh fetch tasks are relevant anyways.
   - In addition, the RT archiver relies on having low I/O latency with Redis to
     minimize the latency of fetch starts. Due to these considerations, this Redis
     instance should **NOT** be used for any other applications.
3. Some number (greater than 1) of consumer pods that execute enqueued fetch tasks, making HTTP requests and saving the raw responses (and metadata such as headers) to GCS
   - Each consumer pod runs some number of worker threads

These deployments are defined in the [relevant kubernetes manifests](../../kubernetes/apps/manifests/gtfs-rt-archiver-v3) and overlaid with kustomize at [gtfs-rt-archiver-v3-prod](../../kubernetes/apps/overlays/gtfs-rt-archiver-v3-prod).

> **Note:** The in-cluster archiver is currently dormant — all three deployments are scaled to 0 replicas via the prod overlay. Production GTFS-RT archiving runs out of cluster. The chart, overlay, and image build are kept in source so the in-cluster archiver can be revived if needed; reviving it would also require re-establishing observability (metrics scraping, dashboards, alerts, error reporting), since the previous Grafana / Sentry / managed-Prometheus setup has been decommissioned.

## Error classes

The archiver emits a few classes of error worth understanding when operating it:

- Failure to connect to Redis following a node upgrade; typically fixed by [restarting the archiver](#restarting-the-archiver).
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

So for example, to restart all 3 deployments, you would run the following.

```shell
kubectl rollout restart deployment.apps/redis -n gtfs-rt-v3
kubectl rollout restart deployment.apps/gtfs-rt-archiver-ticker -n gtfs-rt-v3
kubectl rollout restart deployment.apps/gtfs-rt-archiver-consumer -n gtfs-rt-v3
```

### Deploying configuration changes

Environment-agnostic configurations live in [app vars](../../kubernetes/apps/manifests/gtfs-rt-archiver-v3/archiver-app-vars.yaml) while environment-specific configurations live in [channel vars](../../kubernetes/apps/overlays/gtfs-rt-archiver-v3-prod/archiver-channel-vars.yaml). You can edit these files and deploy the changes with `kubectl`.

```
kubectl apply -k apps/overlays/gtfs-rt-archiver-v3-prod
```

Running `apply` will also deploy the archiver from scratch if it is not deployed yet, as long as the proper namespace exists.

### Deploying code changes

Code changes require building and pushing a new Docker image, as well as applying `kubectl` changes to point the deployment at the new image.

1. Make code changes and increment version in `pyproject.toml`
   1. Ex. `poetry version 2023.4.10`
2. Open a pull request and verify that the test container image build succeeds
3. Merge the pull request and obtain the new image tag from the GitHub Actions build output or from <https://github.com/cal-itp/data-infra/pkgs/container/data-infra%2Fgtfs-rt-archiver-v3>
4. Change image tag version in the environments `kustomization.yaml`.
   1. Ex. change the value of `newTag` to '`2023.4.10-a66f90'`
5. Finally, apply changes in production by opening and merging a second PR that includes the `kustomization.yaml` changes.

### Changing download configurations

GTFS download configurations (for both Schedule and RT) are sourced from the [GTFS Dataset table](https://airtable.com/appPnJWrQ7ui4UmIl/tbl5V6Vjs4mNQgYbc) in the California Transit Airtable base, and we have [specific documentation](https://docs.google.com/document/d/1IO8x9-31LjwmlBDH0Jri-uWI7Zygi_IPc9nqd7FPEQM/edit#heading=h.b2yta6yeugar) for modifying the table. (Both of these Airtable links require authentication/access to Airtable.) You may need to make URL or authentication adjustments in this table. This data is downloaded daily into our infrastructure and will propagate to the GTFS Schedule and RT downloads; you may execute the [Airtable download job](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/airtable_loader_v2/grid) manually after making edits to "deploy" the changes more quickly.

Another possible intervention is updating or adding authentication information in [Secret Manager](https://console.cloud.google.com/security/secret-manager). You may create new versions of existing secrets, or add entirely new secrets. Secrets must be tagged with `gtfs_rt: true` to be loaded as secrets in the archiver; secrets are refreshed every 5 minutes by the ticker.
