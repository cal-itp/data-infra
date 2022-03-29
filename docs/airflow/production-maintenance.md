# Production Maintenance

_Edited April 2022_

Sometimes DAGs will fail in production. Below are considerations to take into account when re-running or clearing DAGs to address failures. DAGs are listed in alphabetical order.

Summary of key considerations:
* **Can re-run after 24h?** - some DAGs scrape data and then label that data based on execution date (i.e., if they are run more than 24h after they were scheduled, they will pull data from one day and label it as having come from a prior day.) Long-term we will work to break this pattern, but until those changes are made, these DAGs should **not** be re-run 24 hours after originally scheduled (including backfills).
* **`depends_on_past`** - Some DAGs depend on a prior day's run having completed successfully, denoted by the `depends_on_past` flag. This means that if the DAG fails for multiple days, each day must be re-run in order.
* **Covers all of history?** - Some DAGs' contents contain only operations that cover all of history, even when only for one day (i.e., none of their tasks do anything that is specific to their `execution_date`.)

| DAG | Can re-run after 24h? | `depends_on_past` | Covers all of history? |
| --- | --- | --- | --- |
`airtable_loader` | **No** | No | No |
`airtable_views` | Yes | No | No |


## `airtable_loader`

This DAG should not be re-run more than 24 hours after its initial

From time-to-time some DAGs may need to be re-ran in order to populate new data.

More will be added later, but whenever backfilling of DAG tasks need to happen, the following command can be ran:

```shell
gcloud composer environments run calitp-airflow-prod --location=us-west2 backfill -- --start_date 2021-04-18 --end_date 2021-11-03 -x --reset_dagruns -y -t "gtfs_schedule_history_load" -i gtfs_loader
```
