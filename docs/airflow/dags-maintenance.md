(dags-maintenance)=

# Airflow Operational Considerations

We use [Airflow](https://airflow.apache.org/) to orchestrate our data ingest processes. This page describes how to handle cases where an Airflow [DAG task](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/tasks.html) fails. For general information about Airflow development, see the [Airflow README in the data-infra GitHub repo](https://github.com/cal-itp/data-infra/blob/main/airflow/README.md).

## Monitoring DAGs

When an Airflow DAG task fails, it will alert to the `#alerts-data-infra` channel in Slack.

In that case, someone should respond according to the considerations described below and in each individual DAG's documentation (available in [each DAG subdirectory](https://github.com/cal-itp/data-infra/tree/main/airflow/dags) in the `data-infra` GitHub repository).

### Considerations for re-running or clearing DAGs

Below are considerations to take into account when re-running or clearing DAGs to address failures. You can [consult the individual DAG's documentation](https://github.com/cal-itp/data-infra/tree/main/airflow/dags) for information on which of the following categories each DAG falls into.

#### Now vs. data interval processing

There are roughly two types of Airflow DAGs in our system:

- "Now" DAGs - mostly for executing code on a schedule (often scraping current data, or a fancy cron job), NOT orchestrating distributed processing of existing data
  - **When these DAGs fail, and you'd like to re-run them, you should execute a new manual run rather than clearing a historical run.**
  - Only the actual execution time matters if relevant (usually for timestamping data or artifacts)
  - Generally safe but not useful to execute multiple times simultaneously
  - There is no concept of backfilling via these DAGs
- "Data interval processing" DAGs - these DAGs orchestrate processing of previously-captured data, or data than can be retrieved in a timestamped manner
  - **When these DAGs fail, you should clear the historical task instances that failed.** (Generally, these DAGs are expected to be 100% successful.)
  - **Failures in these jobs may cause data to be missing from the data warehouse in unexpected ways:** if a parse job fails, then the data that should have been processed will not be available in the warehouse. Sometimes this is resolved easily by clearing the failed parse job so that the data will be picked up in the next warehouse run (orchestrated by [the `transform_warehouse` DAG](https://github.com/cal-itp/data-infra/blob/main/airflow/dags/transform_warehouse/)). However, because the data warehouse uses [incremental models](https://docs.getdbt.com/docs/build/incremental-models), it's possible that if the failed job is not cleared quickly enough the missing data will not be picked up because the incremental lookback period will have passed.
  - Relies heavily on the [`execution_date` or `data_interval_start/end`](https://airflow.apache.org/docs/apache-airflow/stable/templates-ref.html) concepts
  - May not be entirely idempotent though we try; for example, validating RT data depends on Schedule data which may be late-arriving
  - Backfilling can generally be performed by clearing past task instances and letting them re-run
  - We try to avoid `depends_on_past` DAGs, so parallelization is possible during backfills

#### Scheduled vs. ad-hoc

Additionally, DAGs can either be scheduled or ad-hoc:

- **Scheduled** DAGs are designed to be run regularly, based on the [cron schedule](https://airflow.apache.org/docs/apache-airflow/1.10.1/scheduler.html) set in the DAG's `METADATA.yml` file. All "data interval processing" DAGs will be scheduled.
- **Ad-hoc** DAGs are designed to be run as one-offs, to automate a workflow that is risky or difficult for an individual user to run locally. These will have `schedule_interval: None` in their `METADATA.yml` files. Only "now" DAGs can be ad-hoc.

### How to clear a DAG or DAG task

Failures can be cleared (re-run) via the Airflow user interface ([accessible via Composer here](https://console.cloud.google.com/composer/environments?project=cal-itp-data-infra&supportedpurview=project).)

[This Airflow guide](https://airflow.apache.org/docs/apache-airflow/stable/ui.html) can help you use and interpret the Airflow UI.

## `PodOperators`

When restarting a failed run of a DAG that utilizes a `PodOperator`, check the logs before restarting. If the logs show any indication that the prior run's pod was not killed (for example, if the logs cut off abruptly without showing an explicit task failure), you should check that the [Kubernetes pod](https://kubernetes.io/docs/concepts/workloads/pods/) associated with the failed run task has in fact been killed before clearing or restarting the Airflow task. Users with proper access to Kubernetes Engine in Google Cloud can check for any [live workloads](<https://console.cloud.google.com/kubernetes/workload/overview?project=cal-itp-data-infra&pli=1&pageState=(%22savedViews%22:(%22i%22:%229699ac902c0a41ae918282ebfa4f5fb2%22,%22c%22:%5B%5D,%22n%22:%5B%5D),%22workload_list_table%22:(%22p%22:0))>) that correspond to the pod referenced in the failed Airflow task's run logs.

## Backfilling from the command line

From time to time some DAGs may need to be re-run in order to populate new data.

Subject to the considerations outlined above, backfilling can be performed by clearing historical runs in the web interface, or via the CLI:

```shell
gcloud composer environments run calitp-airflow-prod --location=us-west2 backfill -- --start_date 2021-04-18 --end_date 2021-11-03 -x --reset_dagruns -y -t "gtfs_schedule_history_load" -i gtfs_loader
```
