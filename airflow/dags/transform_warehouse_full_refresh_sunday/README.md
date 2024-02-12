# `transform_warehouse_full_refresh_sunday`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the running of the Cal-ITP dbt project and deployment of associated artifacts like the [dbt docs site](https://dbt-docs.calitp.org/#!/overview) with the [`--full-refresh` flag set](https://docs.getdbt.com/docs/build/incremental-models#how-do-i-rebuild-an-incremental-model). This DAG runs every Sunday to allow non-RT incremental models to be regularly rebuilt from scratch, so as to reflect recent code changes if they occur.

To be cost-effective, it only runs a `dbt run --full-refresh` on non-RT data, and afterwards runs a normal `dbt run` on the (more expensive) RT data. It also runs `dbt test` after each run for the data transformed.

The dependencies are configured in this order:
* `dbt_run_and_upload_artifacts_full_refresh_exclude_rt`
  * full-refresh run of only non-RT data (`--exclude source:external_gtfs_rt+ source:gtfs_rt_external_tables+`)
* `dbt_test_exclude_rt`
  * tests only non-RT data (`--exclude source:external_gtfs_rt+ source:gtfs_rt_external_tables+`)
* `dbt_run_and_upload_artifacts_select_rt`
  * normal dbt run of RT data (`--select source:external_gtfs_rt+`)
* `dbt_test_select_rt`
  * test only non-RT data (`--select source:external_gtfs_rt+`)

This DAG has some special considerations:

- If a task fails, look carefully before assuming that clearing the task will help. If the failure was caused by a `DbtModelError`, there is an issue with the SQL or data in an individual model and clearing the task will not help until that issue is fixed.

- Because the tasks in this DAG involve running a large volume of SQL transformations, they risk triggering data quotas if the DAG is run multiple times in a single day.
