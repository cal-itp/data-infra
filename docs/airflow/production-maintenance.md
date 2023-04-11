# Production Maintenance

_Last edited: May 5, 2022_

## Re-running or clearing DAGs

Sometimes DAGs will fail in production. Below are considerations to take into account when re-running or clearing DAGs to address failures.

There are roughly two categories of Airflow DAGs in our system.
* "Now" DAGs - mostly for executing code on a schedule (often scraping current data, or a fancy cron job), NOT orchestrating distributed processing of existing data
  * Only the actual execution time matters if relevant (usually for timestamping data or artifacts)
  * Generally safe but not useful to execute multiple times simultaneously
  * There is no concept of backfilling via these DAGs; they may output data/artifacts that require "backfilling" (i.e. modifying existing data) via a script or notebook
* "Data interval processing" DAGs - orchestrates processing of previously-captured data, or data than can be retrieved in a timestamped manner (e.g. Amplitude)
  * Relies heavily on the `execution_date` or `data_interval_start/end` concepts
  * May not be entirely idempotent though we try; for example, validating RT data depends on Schedule data which may be late-arriving
  * Backfilling can generally be performed by clearing past task instances and letting them re-run
  * We try to avoid `depends_on_past` DAGs, so parallelization is possible during backfills

DAGs are listed in alphabetical order (like in the Airflow UI) and are labeled by

| DAG                                | "Now" | Notes                                                                                                     |
|------------------------------------|-------|-----------------------------------------------------------------------------------------------------------|
| `airtable_loader_v2`               | Yes   | Don't need to rerun more than once if multiple failures; scraped data is labeled by actual execution time |
| `amplitude_benefits`               | No    | This will be replaced soon by an Amplitude-to-GCS export.                                                 |
| `create_external_tables`           | Yes   | Generally only fails due to GCP issues or definition problems; individual tasks can be cleared once fixed |
| `deploy_dbt_docs`                  | Yes   | Manual job to deploy dbt docs to Metabase and Netlify                                                     |
| `download_gtfs_schedule_v2`        | Yes   | Don't need to rerun more than once if multiple failures; scraped data is labeled by actual execution time |
| `parse_and_validate_rt_v2`         | No    |                                                                                                           |
| `payments_loader`                  | Yes   | This is deprecated, pending data consumers switching to v2 models.                                        |
| `scrape_feed_aggregators`          | Yes   |                                                                                                           |
| `transform_warehouse`              | Yes   | Outputs timestamped artifacts                                                                             |
| `transform_warehouse_full_refresh` | Yes   | Manual job to execute a full-refresh dbt job; should be used sparingly; outputs timestamped artifacts     |
| `unzip_and_validate_gtfs_schedule` | No    |                                                                                                           |

### Deprecated DAGs

The following DAGs are still listed in the Airflow UI even though they are **deprecated or indefinitely paused**. They never need to be re-run.

* `check_data_freshness`

## Task-level considerations

Some tasks have unique considerations, beyond the requirements of their overall DAG.

* **`PodOperators`**: When restarting a failed `PodOperator` run, check the logs before restarting. If the logs show any indication that the prior run's pod was not killed (for example, if the logs cut off abruptly without showing an explicit task failure), you should check that the pod associated with the failed run task has in fact been killed before clearing or restarting the Airflow task. If you don't know how to check a pod status, please ask in the `#data-infra` channel on Slack before proceeding.

## Backfilling from the command line

From time-to-time some DAGs may need to be re-ran in order to populate new data.

Subject to the considerations outlined abov, backfilling can be performed by clearing historical runs in the web interface, or via the CLI:
```shell
gcloud composer environments run calitp-airflow-prod --location=us-west2 backfill -- --start_date 2021-04-18 --end_date 2021-11-03 -x --reset_dagruns -y -t "gtfs_schedule_history_load" -i gtfs_loader
```
