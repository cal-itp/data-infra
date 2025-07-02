# `transform_warehouse_full_refresh`

Type: [Now / Ad-Hoc](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the running of the Cal-ITP dbt project and deployment of associated artifacts like the [dbt docs site](https://dbt-docs.dds.dot.ca.gov/#!/overview) with the [`--full-refresh` flag set](https://docs.getdbt.com/docs/build/incremental-models#how-do-i-rebuild-an-incremental-model) so that incremental models will be rebuilt from scratch.

**This task should generally only be run with a `dbt_select` statement provided:** (use the `Trigger DAG w/ config` button in the Airflow UI (option under the "play" icon in the upper right corner when looking at an individual DAG) and provide a JSON configuration like `{"dbt_select": "<+ if you want to full refresh parents><your_model_here><+ if you want to full refresh children>"}` using [dbt selection syntax](https://docs.getdbt.com/reference/node-selection/syntax#specifying-resources)).  **Note that all models selected by the selection syntax will be full-refreshed! Check all the incremental models selected by your syntax using the following from the command line in the repo's warehouse folder `poetry run dbt ls -s <your select statement here>,config.materialized:incremental --resource-type model`.**

If you need to run this DAG without any selection criteria specified (i.e., full refresh literally everything), you may need to increase the BigQuery quota for the project; refreshing all the GTFS-RT models uses up to ~60 TB as of 7/26/23.

See the [`transform_warehouse` README](../transform_warehouse/README.md) for general considerations for running the dbt DAGs.
