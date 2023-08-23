# `deploy_dbt_docs`

Type: [Now / Ad-Hoc](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the deployment of our [dbt docs site](https://dbt-docs.calitp.org/#%21/overview). It is designed primarily to be a one-off to be run if the docs site deploy portion of [`transform_warehouse`](./transform_warehouse/README.md) fails and we want a way to re-run only the docs part of that job.
