(architecture-data)=

# Data pipelines

In general, our data ingest follows versions of the pattern diagrammed below. For an example PR that ingests a brand new data source from scratch, see [data infra PR #2376](https://github.com/cal-itp/data-infra/pull/2376).

Some of the key attributes of our approach:

- We generate an [`outcomes`](https://github.com/cal-itp/data-infra/blob/main/packages/calitp-data-infra/calitp_data_infra/storage.py#L418) file describing whether scrape, parse, or validate operations were successful. This makes operation outcomes visible in BigQuery, so they can be analyzed (for example: how long has the download operation for X feed been failing?)
- We try to limit the amount of manipulation in Airflow tasks to the bare minimum to make the data legible to BigQuery (for example, replace illegal column names that would break the external tables.) We use gzipped JSONL files in GCS as our default parsed data format.
- [External tables](https://cloud.google.com/bigquery/docs/external-data-sources#external_tables) provide the interface between ingested data and BigQuery modeling/transformations.

While many of the key elements of our architecture are common to most of our data sources, each data source has some unique aspects as well. [This spreadsheet](https://docs.google.com/spreadsheets/d/1bv1K5lZMnq1eCSZRy3sPd3MgbdyghrMl4u8HvjNjWPw/edit#gid=0) details overviews by data source, outlining the specific code/resources that correspond to each step in the general data flow shown below.

(data-ingest-diagram)=

## Data ingest diagram

```{mermaid}
flowchart TD

raw_data((Raw data  <br> in external source))
airflow_scrape{<b>Airflow</b>: <br> scraper}
airflow_parse{<b>Airflow</b>: <br> parser}
airflow_validate{<b>Airflow</b>: <br> GTFS validator}
airflow_external_tables{<b>Airflow</b>: <br> create<br>external tables}
dbt([<br><b>dbt</b><br><br>])
airflow_dbt{<b>Airflow</b>: <br> run dbt}

subgraph first_bq[ ]
    bq_label1[BigQuery<br>External tables dataset]
    ext_raw_outcomes[(Scrape outcomes<br>external table)]
    ext_parse_data[(Parsed data<br>external table)]
    ext_parse_outcomes[(Parse outcomes<br>external table)]
    ext_validations[(Validations<br>external table)]
    ext_validation_outcomes[(Validation outcomes<br>external table)]
end

subgraph second_bq[ ]
    bq_label2[BigQuery<br>Staging, mart, etc. datasets]
    bq_table_example[(staging_*.table_names)]
    bq_table_example2[(mart_*.table_names)]
    bq_table_example3[(etc.)]
end

subgraph first_gcs[ ]
    gcs_label1[Google Cloud Storage:<br>Raw bucket]
    raw_gcs[Raw data]
    raw_outcomes_gcs[Scrape outcomes file]
end

subgraph second_gcs[ ]
    gcs_label2[Google Cloud Storage:<br>Parsed bucket]
    parse_gcs[Parsed data]
    parse_outcomes_gcs[Parse outcomes file]
end

subgraph validated_gcs[ ]
    gcs_label3[<i>GTFS ONLY</i> <br> Google Cloud Storage:<br>Validation bucket]
    validation_gcs[Validations data]
    validation_outcomes_gcs[Validation outcomes file]
end

raw_data -- read by--> airflow_scrape
airflow_scrape -- writes data to--> raw_gcs
airflow_scrape -- writes operation outcomes to--> raw_outcomes_gcs
raw_gcs -- read by--> airflow_parse
airflow_parse -- writes data to--> parse_gcs
airflow_parse -- writes operation outcomes to--> parse_outcomes_gcs

raw_gcs -- if GTFS then read by--> airflow_validate
airflow_validate -- writes data to--> validation_gcs
airflow_validate -- writes operation outcomes to--> validation_outcomes_gcs

parse_outcomes_gcs -- external tables  defined by--> airflow_external_tables
parse_gcs -- external tables  defined by--> airflow_external_tables
raw_outcomes_gcs -- external tables  defined by--> airflow_external_tables
validation_outcomes_gcs -- external tables  defined by--> airflow_external_tables
validation_gcs -- external tables  defined by--> airflow_external_tables


airflow_external_tables -- defines--> ext_raw_outcomes
airflow_external_tables -- defines--> ext_parse_data
airflow_external_tables -- defines--> ext_parse_outcomes
airflow_external_tables -- defines--> ext_validation_outcomes
airflow_external_tables -- defines--> ext_validations

airflow_dbt -- runs--> dbt
ext_raw_outcomes -- read as source by-->dbt
ext_parse_data -- read as source by-->dbt
ext_parse_outcomes -- read as source by-->dbt
ext_validations -- read as source by-->dbt
ext_validation_outcomes -- read as source by-->dbt


dbt -- orchestrates transformations to create-->second_bq

classDef default fill:white, color:black, stroke:black, stroke-width:1px

classDef gcs_group_boxstyle fill:lightblue, color:black, stroke:black, stroke-width:1px

classDef bq_group_boxstyle fill:lightgreen, color:black, stroke:black, stroke-width:1px

classDef raw_datastyle fill:yellow, color:black, stroke:black, stroke-width:1px

classDef dbtstyle fill:darkgreen, color:white, stroke:black, stroke-width:1px

classDef group_labelstyle fill:lightgray, color:black, stroke-width:0px

class raw_data raw_datastyle
class dbt dbtstyle
class first_gcs,second_gcs,validated_gcs gcs_group_boxstyle
class first_bq,second_bq bq_group_boxstyle
class gcs_label1,gcs_label2,gcs_label3,bq_label1,bq_label2 group_labelstyle
```

## Adding a new data source

Adding a new data source based on the architecture described above involves several steps, outlined below.

```{note}
If you're bringing in data that is similar to existing data (for example, a new subset of an existing dataset like a new Airtable or Littlepay table), you should follow the existing pattern for that dataset. [This spreadsheet](https://docs.google.com/spreadsheets/d/1bv1K5lZMnq1eCSZRy3sPd3MgbdyghrMl4u8HvjNjWPw/edit#gid=0) gives overviews of some prominent existing data sources, outlining the specific code/resources that correspond to each step in the [general data flow](data-ingest-diagram) for that data source.
```

### Determine upstream source type

To determine the best storage location for your raw data (especially if it requires manual curation), consult the [Data Storage Guidance within the Cal-ITP Data Pipeline Google Doc](https://docs.google.com/document/d/1-l6c99UUZ0o3Ln9S_CAt7iitGHvriewWhKDftESE2Dw/edit).

The [Should it be a dbt model?](tool_choice) docs section also has some guidance about when a data pipeline should be created.

### Bring data into Google Cloud Storage

We store our raw, un-transformed data in Google Cloud Storage to ensure that we can always recover the raw data if needed.

We store data in [hive-partitioned buckets](https://cloud.google.com/bigquery/docs/hive-partitioned-queries#supported_data_layouts) so that data is clearly labeled and partitioned for better performance. We use UTC dates and timestamps in hive paths (for example, for the timestamp of the data extract) for consistency.

You will need to set up a way to bring your raw data into the Cal-ITP Google Cloud Storage environment. Most commonly, we use [Airflow](https://airflow.apache.org/) for this.

The [Airflow README in the data-infra repo](https://github.com/cal-itp/data-infra/tree/main/airflow#readme) has information about how to set up Airflow locally for testing and how the Airflow project is structured.

We often bring data into our environment in two steps, created as two separate Airflow [DAGs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html):

- **Sync the fully-raw data in its original format:** See for example the changes in the `airflow/dags/sync_elavon` directory in [data-infra PR #2376](https://github.com/cal-itp/data-infra/pull/2376/files). We do this to preserve the raw data in its original form. This data might be saved in a `calitp-<your-data-source>-raw` bucket.
- **Convert the saved raw data into a BigQuery-readable gzipped JSONL file:** See for example the changes in the `airflow/dags/parse_elavon` directory in [data-infra PR #2376](https://github.com/cal-itp/data-infra/pull/2376/files). This prepares the data is to be read into BigQuery. **Conversion here should be limited to the bare minimum needed to make the data BigQuery-compatible, for example converting column names that would be invalid in BigQuery and changing the file type to gzipped JSONL.** This data might be saved in a `calitp-<your-data-source>-parsed` bucket.

```{note}
When you merge a pull request creating a new Airflow DAG, that DAG will be paused by default. To start the DAG, someone will need to log into the Airflow UI and unpause the DAG. 
```

### Create external tables

We use [external tables](https://cloud.google.com/bigquery/docs/external-data-sources#external_tables) to allow BigQuery to query data stored in Google Cloud Storage. External tables do not move data into BigQuery, they simply define the data schema which BigQuery can then use to access the data still stored in Google Cloud Storage.

External tables are created by the [`create_external_tables` Airflow DAG](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/create_external_tables) using the [ExternalTable custom operator](https://github.com/cal-itp/data-infra/blob/main/airflow/plugins/operators/external_table.py). Testing guidance and example YAML for how to create your external table is provided in the [Airflow DAG documentation](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/create_external_tables#create_external_tables).

### dbt modeling

Considerations for dbt modeling are outlined on the [Developing models in dbt](developing-dbt-models) page.
