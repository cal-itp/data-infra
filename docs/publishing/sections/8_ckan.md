(publishing-ckan)=
# Publishing data to California Open Data aka CKAN

NOTE: Only non-spatial data should be directly published to CKAN. Spatial data
(i.e. data keyed by location in some manner) has to go through the Caltrans
geoportal and is subsequently synced to CKAN.

## What is the California Open Data Portal?

The state of California hosts its own instance of CKAN, called the [California Open Data Portal](https://data.ca.gov/).
[CKAN](https://ckan.org/) is an open-source data management tool; in other words,
it allows organizations such as Caltrans to host data so that users can search
for and download data sets that might be useful for analysis or research. Among
other agencies, Caltrans publishes [many data sets](https://data.ca.gov/organization/caltrans) to CKAN.
Data is generally published as flat files (typically CSV) alongside required
metadata and a data dictionary.

## Cal-ITP data sets
* [Cal-ITP GTFS Schedule Data](https://data.ca.gov/dataset/cal-itp-gtfs-ingest-pipeline-dataset)

## General process
### Develop data models
Generally, data models should be built in dbt/BigQuery if possible. For example,
we have [latest-only GTFS schedule models](https://github.com/cal-itp/data-infra/tree/main/warehouse/models/gtfs_schedule_latest_only)
we can use to update and expand the existing [CKAN dataset](https://data.ca.gov/dataset/cal-itp-gtfs-ingest-pipeline-dataset)
[latest-only agency](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.agency)

### Document data
California Open Data requires two documentation files for published datasets.
1. `metadata.csv` - one row per resource (i.e. file) to be published
2. `dictionary.csv` - one row per column across all resources

If you are using dbt exposure-based data publishing, you can automatically generate
these two files using the main `publish.py` script (specifically the `generate-exposure-documentation`
subcommand). The documentation from the dbt models' corresponding YAML will be
converted into appropriate CSVs and written out locally.

Run this command inside the `warehouse` folder, assuming you have local dbt
artifacts in `target/` from a `dbt run` or `dbt compile`.
```bash
poetry run python scripts/publish.py generate-exposure-documentation california_open_data
```

Generally, we recommend executing the dbt models locally and using your local
artifacts to produce the data to be generated; this ensures the data is
up-to-date and fits nicely into a tool-enabled manual workflow.

### Create dataset and metadata
Once you've generated the necessary metadata and dictionary CSV, you need to get
approval from Chad Baker. Send the CSVs via email, preferably CC'ing somebody
with a Caltrans email.

Once approved, a CKAN dataset will be created with UUIDs corresponding to each
model that will be published. If you are using dbt exposures, you will need to
update the `meta` field to map the dbt models to the appropriate UUIDs.

An example from the latest-only GTFS data exposure.
```yaml
    meta:
      methodology: |
        Cal-ITP collects the GTFS feeds from a statewide list [link] every night and aggegrates it into a statewide table
        for analysis purposes only. Do not use for trip planner ingestation, rather is meant to be used for statewide
        analytics and other use cases. Note: These data may or may or may not have passed GTFS-Validation.
      coordinate_system_espg: "EPSG:4326"
      destinations:
        - type: ckan
          format: csv
          url: https://data.ca.gov
          resources:
            agency:
              id: e8f9d49e-2bb6-400b-b01f-28bc2e0e7df2
              description: |
                Each row is a cleaned row from an agency.txt file.
                Definitions for the original GTFS fields are available at:
                https://gtfs.org/reference/static#agencytxt.
            attributions:
              id: 038b7354-06e8-4082-a4a1-40debd3110d5
              description: |
                Each row is a cleaned row from an attributions.txt file.
                Definitions for the original GTFS fields are available at:
                https://gtfs.org/reference/static#attributionstxt.
```

### Publish the data!
If you are using dbt-based publishing, the `publish_exposure` subcommand of `publish.py`
will query BigQuery, write out CSV files, and upload those files to CKAN.
Either create an Airflow job to refresh/update the data at the specified
frequency, or do it manually. You can use flags to execute a dry run or write to
GCS without also uploading to CKAN.

If you are running `publish.py` locally, you will need to set `$CALITP_CKAN_GTFS_SCHEDULE_KEY`
ahead of time.

By default, the script will attempt to use the latest manifest uploaded by the
Airflow dbt task, and then will write out artifacts to GCS, but will not actually
upload data to CKAN. In addition, the script will upload the metadata and dictionary
files to GCS for eventual sharing with Caltrans.
```bash
$ poetry run python scripts/publish.py publish-exposure california_open_data --manifest ./target/manifest.json
reading manifest from ./target/manifest.json
would be writing to gs://test-calitp-publish/california_open_data__metadata/dt=2022-08-30/ts=2022-08-30T20:46:00.474199Z/metadata.csv
would be writing to gs://test-calitp-publish/california_open_data__dictionary/dt=2022-08-30/ts=2022-08-30T20:46:00.474199Z/dictionary.csv
handling agency e8f9d49e-2bb6-400b-b01f-28bc2e0e7df2
...
writing 346 rows (42.9 kB) from andrew_gtfs_schedule.agency to gs://test-calitp-publish/california_open_data__agency/dt=2022-08-30/ts=2022-08-30T20:46:00.474199Z/agency.csv
would be uploading to https://data.ca.gov e8f9d49e-2bb6-400b-b01f-28bc2e0e7df2 if --publish
...
```

You can add the `--publish` flag to actually upload artifacts to CKAN after they
are written to GCS. You must be using a production bucket to publish, either
by setting `$CALITP_BUCKET__PUBLISH` or using the `--bucket` flag. In addition,
you may specify a manifest file in GCS if desired.
```bash
poetry run python scripts/publish.py publish-exposure california_open_data --bucket gs://calitp-publish --manifest gs://calitp-dbt-artifacts/latest/manifest.json --publish
```
