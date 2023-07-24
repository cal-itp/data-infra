# `parse_and_validate_rt_v2`

Type: [Data interval processing / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the parsing and validation of GTFS RT data downloaded by the [archiver](../../../services/gtfs-rt-archiver-v3/README.md).

**Failures in this job may cause data to be missing from the data warehouse in unexpected ways:** if a parse job fails, then the data that should have been processed will not be available in the warehouse. Sometimes this is resolved easily by clearing the failed parse job so that the data will be picked up in the next warehouse run (orchestrated by [the `transform_warehouse` DAG](../transform_warehouse/README.md)). However, because the data warehouse uses [incremental models](https://docs.getdbt.com/docs/build/incremental-models), it's possible that if the failed job is not cleared quickly enough the missing data will not be picked up because the incremental lookback period will have passed.
