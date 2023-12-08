(common-developer-workflows)=

# Common Developer Workflows

A centralized list of common developer workflows.

## Adding a new data source

One of the most common requests in the Cal-ITP warehouse is to add a new data source to the warehouse. For an architectural overview of how we usually structure data ingest, see [our Data Pipelines architecture overview](architecture-data)

```{note}
If you're bringing in data that is similar to existing data (for example, a new subset of an existing dataset like a new Airtable or Littlepay table), you should follow the existing pattern for that dataset.  [This spreadsheet](https://docs.google.com/spreadsheets/d/1bv1K5lZMnq1eCSZRy3sPd3MgbdyghrMl4u8HvjNjWPw/edit#gid=0) gives overviews of some prominent existing data sources, outlining the specific code/resources that correspond to each step in the [general data flow](data-ingest-diagram) for that data source.
```

Adding a new data source involves several steps, outlined below.

### Determine upstream source type

To determine the best source location for your raw data, consult the [Data Storage Guidance within the Cal-ITP Data Pipeline Google Doc](https://docs.google.com/document/d/1-l6c99UUZ0o3Ln9S_CAt7iitGHvriewWhKDftESE2Dw/edit).

### Bring data into Google Cloud Storage

We store our raw, un-transformed data in Google Cloud Storage to ensure that we can always recover the raw data if needed.

We store data in [hive-partitioned buckets](https://cloud.google.com/bigquery/docs/hive-partitioned-queries#supported_data_layouts) so that data is clearly labeled and partitioned for better performance. We use UTC dates and timestamps in hive paths (for example, for the timestamp of the data extract) for consistency.

You will need to set up a way to bring your raw data into the Cal-ITP Google Cloud Storage environment. Most commonly, we use [Airflow](https://airflow.apache.org/) for this.

The [Airflow README in the data-infra repo](https://github.com/cal-itp/data-infra/tree/main/airflow#readme) has information about how to set up Airflow locally for testing and how the Airflow project is structured.

We often bring data into our environment in two steps, created as two separate Airflow DAGs:

- **Sync the fully-raw data in its original format:** See for example the changes in the `airflow/dags/sync_elavon` directory in [data-infra PR #2376](https://github.com/cal-itp/data-infra/pull/2376/files). We do this to preserve the raw data in its original form. This data might be saved in a `calitp-<your-data-source>-raw` bucket.
- **Convert the saved raw data into a BigQuery-readable gzipped JSONL file:** See for example the changes in the `airflow/dags/parse_elavon` directory in [data-infra PR #2376](https://github.com/cal-itp/data-infra/pull/2376/files). This data is then ready to be read into BigQuery. **Conversion here should be limited to the bare minimum needed to make the data BigQuery-compatible, for example converting column names that would be invalid in BigQuery and changing the file type to gzipped JSONL.** This data might be saved in a `calitp-<your-data-source>-parsed` bucket.
