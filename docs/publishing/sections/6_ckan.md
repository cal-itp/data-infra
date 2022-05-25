(publishing-ckan=)
General process (with GTFS Schedule as an example)
# Publishing data to CKAN

## What is CKAN?

## General process
### Develop data models
a. For example, we have [latest-only GTFS schedule models](https://github.com/cal-itp/data-infra/tree/main/warehouse/models/gtfs_schedule_latest_only) we can use to update and expand the existing [CKAN dataset](https://data.ca.gov/dataset/cal-itp-gtfs-ingest-pipeline-dataset)
b. [latest-only agency](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.agency)

### Document data
a. We should generally be documenting both individual data models and rows
within those models
b. In a dbt-based model, this would correspond to model and column descriptions

### Create dataset and metadata
a. Generate metadata and data dictionary CSVs
b. Email Chad Baker
    i. Keep somebody with a Caltrans email in the loop (e.g. Eric)

### Publish the data!
a. Either create an Airflow job to refresh/update the data at the specified
frequency, or do it manually.
