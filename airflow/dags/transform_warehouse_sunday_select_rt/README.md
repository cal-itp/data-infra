# `transform_warehouse_sunday_select_rt`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the running of the Cal-ITP dbt project and deployment of associated artifacts like the [dbt docs site](https://dbt-docs.calitp.org/#!/overview) on Sunday, and runs only RT data (`--select gtfs_rt_external_tables+`). This DAG run compliments our other Sunday DAG run: `transform_warehouse_sunday_full_refresh_exclude_rt`.

This DAG has some special considerations:

- If a task fails, look carefully before assuming that clearing the task will help. If the failure was caused by a `DbtModelError`, there is an issue with the SQL or data in an individual model and clearing the task will not help until that issue is fixed.

- While this DAG does not have any formal dependencies on other DAGs, the data transformations within the dbt project do depend on successful upstream data capture and parsing.

- Because the tasks in this DAG involve running a large volume of SQL transformations, they risk triggering data quotas if the DAG is run multiple times in a single day.
