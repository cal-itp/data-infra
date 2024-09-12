# `transform_warehouse`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the running of the Cal-ITP dbt project and deployment of associated artifacts like the [dbt docs site](https://dbt-docs.calitp.org/#!/overview).

This DAG has some special considerations:

- The schedule interval is 14:00 UTC Mondays to Saturdays. Mondays will be actually running the data interval for the previous Saturday-Sunday.

- This DAG should not run on Sundays because of the other DAG `transform_warehouse_full_refresh_sunday`.

- If a task fails, look carefully before assuming that clearing the task will help. If the failure was caused by a `DbtModelError`, there is an issue with the SQL or data in an individual model and clearing the task will not help until that issue is fixed.

- While this DAG does not have any formal dependencies on other DAGs, the data transformations within the dbt project do depend on successful upstream data capture and parsing.

- Because the tasks in this DAG involve running a large volume of SQL transformations, they risk triggering data quotas if the DAG is run multiple times in a single day.

- This task can be run with a `dbt_select` statement provided (use the `Trigger DAG w/ config` button (option under the "play" icon in the upper right corner when looking at an individual DAG) in the Airflow UI and provide a JSON configuration like `{"dbt_select": "<+ if you want to run parents><your_model_here><+ if you want to run children>"}` using [dbt selection syntax](https://docs.getdbt.com/reference/node-selection/syntax#specifying-resources)) to re-run a specific individual model's lineage.
