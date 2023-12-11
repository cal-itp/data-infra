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
