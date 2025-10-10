# Jobs

Each subfolder here corresponds to a Docker image that utilizes a standalone script to perform a task, usually called in producton by an Airflow DAG.

## Testing Changes

A person with Docker set up locally can build a new version of each image at any time after making changes. From the relevant subfolder, run

```bash
docker build -t ghcr.io/cal-itp/data-infra/gtfs-schedule-validator:[NEW VERSION TAG] .
```

That image can be used alongside [a local Airflow instance](../airflow/README.md) to test the changed job locally prior to merging.

## Deploying Changes to Production

When changes are finalized, a new version number should be specified in the given subfolder's `pyproject.toml` file. When changes to this directory are merged into `main`, a GitHub Action called `build-[JOB NAME]` automatically publishes an updated version of the image. A contributor with proper GHCR permissions can also manually deploy a new version of the image via the CLI:

```bash
docker build -t ghcr.io/cal-itp/data-infra/gtfs-schedule-validator:[NEW VERSION TAG] .
docker push ghcr.io/cal-itp/data-infra/gtfs-schedule-validator:[NEW VERSION TAG]
```

After deploying, no additional steps should be necessary. All internal code referencing the `gtfs-schedule-validator` jobs utilize [the Airflow image_tag macro](../airflow/dags/macros.py) to automatically fetch the latest version during DAG runs.
