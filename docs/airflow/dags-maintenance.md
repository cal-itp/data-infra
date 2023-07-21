(dags-maintenance)=
# Production DAGs Maintenance

## Monitoring DAGs

When an [Airflow](https://airflow.apache.org/) [DAG task](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/tasks.html) fails, it will alert to the `#data-infra-alerts` channel in Slack. In that case, someone should take one of the actions below via the Airflow user interface ([accessible via Composer here](https://console.cloud.google.com/composer/environments?project=cal-itp-data-infra&supportedpurview=project).) [This Airflow guide](https://airflow.apache.org/docs/apache-airflow/stable/ui.html) can help you use and interpret the Airflow UI.


## Re-running or clearing DAGs

Below are considerations to take into account when re-running or clearing DAGs to address failures.

There are roughly two types of Airflow DAGs in our system:
* "Now" DAGs - mostly for executing code on a schedule (often scraping current data, or a fancy cron job), NOT orchestrating distributed processing of existing data
  * **When these DAGs fail, and you'd like to re-run them, you should execute a new manual run rather than clearing a historical run.**
  * Only the actual execution time matters if relevant (usually for timestamping data or artifacts)
  * Generally safe but not useful to execute multiple times simultaneously
  * There is no concept of backfilling via these DAGs
* "Data interval processing" DAGs - orchestrates processing of previously-captured data, or data than can be retrieved in a timestamped manner (e.g. Amplitude)
  * **When these DAGs fail, you should clear the historical task instances that failed.** (Generally, these DAGs are expected to be 100% successful.)
  * Relies heavily on the [`execution_date` or `data_interval_start/end`](https://airflow.apache.org/docs/apache-airflow/stable/templates-ref.html) concepts
  * May not be entirely idempotent though we try; for example, validating RT data depends on Schedule data which may be late-arriving
  * Backfilling can generally be performed by clearing past task instances and letting them re-run
  * We try to avoid `depends_on_past` DAGs, so parallelization is possible during backfills

Additionally, DAGs can either be scheduled or ad-hoc:

* **Scheduled** DAGs are designed to be run regularly, based on the [cron schedule](https://airflow.apache.org/docs/apache-airflow/1.10.1/scheduler.html) set in the DAG's `METADATA.yml` file
* **Ad-hoc** DAGs are designed to be run as one-offs, to automate a workflow that is risky or difficult for an individual user to run locally

You can [consult the individual DAG's documentation](https://github.com/cal-itp/data-infra/tree/main/airflow/dags) for information on what categories each DAG falls into.


### Deprecated DAGs

The following DAGs are still listed in the Airflow UI even though they are **deprecated or indefinitely paused**. They never need to be re-run.

* `amplitude_benefits`
* `check_data_freshness`
* `load-sentry-rtfetchexception-events`

## Task-level considerations

Some tasks have unique considerations, beyond the requirements of their overall DAG.

* **`PodOperators`**: When restarting a failed `PodOperator` run, check the logs before restarting. If the logs show any indication that the prior run's pod was not killed (for example, if the logs cut off abruptly without showing an explicit task failure), you should check that the pod associated with the failed run task has in fact been killed before clearing or restarting the Airflow task. If you don't know how to check a pod status, please ask in the `#data-infra` channel on Slack before proceeding.

## Backfilling from the command line

From time-to-time some DAGs may need to be re-ran in order to populate new data.

Subject to the considerations outlined above, backfilling can be performed by clearing historical runs in the web interface, or via the CLI:
```shell
gcloud composer environments run calitp-airflow-prod --location=us-west2 backfill -- --start_date 2021-04-18 --end_date 2021-11-03 -x --reset_dagruns -y -t "gtfs_schedule_history_load" -i gtfs_loader
```
