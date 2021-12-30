# Production Maintenance

From time-to-time some DAGs may need to be re-ran in order to populate new data.

More will be added later, but whenever backfilling of DAG tasks need to happen, the following command can be ran:

```shell
gcloud composer environments run calitp-airflow-prod --location=us-west2 backfill -- --start_date 2021-04-18 --end_date 2021-11-03 -x --reset_dagruns -y -t "gtfs_schedule_history_load" -i gtfs_loader
```
