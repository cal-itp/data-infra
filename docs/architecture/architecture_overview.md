(architecture-overview)=
# Architecture Overview

The Cal-ITP data infrastructure facilitates several types of data workflows:

* `Ingestion`
* `Modeling/transformation`
* `Analysis`

In addition, we have `Infrastructure` tools that monitor the health of the system itself or deploy or run other services and do not directly interact with data or support end user data access.

At a high level, the following diagram outlines (in very broad terms) the main tools that we use in our data stack (excluding `Infrastructure` tools).

```{mermaid}
flowchart LR
    subgraph ingestion/[ ]
        ingestion_label[Ingestion/Orchestration]
        airflow[Airflow]
        python[Python scripts]
        gcs[Google Cloud Storage]
        airflow --schedules/executes--> python
        python --save data to-->gcs
    end

    subgraph modeling[ ]
        modeling_label[Modeling/Transformation]
        bq[BigQuery]
        dbt[dbt]
        gcs--data read into-->bq
        bq <--SQL data transformations--> dbt
        python -- execute--> dbt
    end

    subgraph analysis[ ]
        analysis_label[Analysis]
        metabase[Metabase]
        jupyter[JupyterHub]
        open_data[California Open Data]
        python -- execute publish to--> open_data
    end

        bq -- data accessible in--> analysis


classDef default fill:white, color:black, stroke:black, stroke-width:1px
classDef group_labelstyle fill:#cde6ef, color:black, stroke-width:0px
class ingestion_label,modeling_label,analysis_label group_labelstyle
```


## Deployed services

Here is a list of services that are deployed as part of the Cal-ITP project.

| Name             | Function                                                                                                                                                                                 | URL                                            | Source code                                                                                         | K8s namespace      | Development/test environment? | Type?
|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|-----------------------------------------------------------------------------------------------------|--------------------|-------------------------------|--------------------|
| Airflow          | General orchestation/automation platform; downloads non-GTFS Realtime data and orchestrates data transformations outside of dbt; executes stateless jobs such as dbt and data publishing | https://o1d2fa0877cf3fb10p-tp.appspot.com/home | https://github.com/cal-itp/data-infra/tree/main/airflow                                             | n/a                | Yes (local)                   | Infrastructure / Ingestion |
| GTFS-RT Archiver | Downloads GTFS Realtime data (more rapidly than Airflow can handle)                                                                                                                      | n/a                                            | https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3                        | gtfs-rt-v3         | Yes (gtfs-rt-v3-test)         | Ingestion |
| Metabase         | Web-hosted BI tool                                                                                                                                                                       | https://dashboards.calitp.org                  | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/metabase                     | metabase           | Yes (metabase-test)           | Analysis |
| Grafana          | Application observability (i.e. monitoring and alerting on metrics)                                                                                                                      | https://monitoring.calitp.org                  | https://github.com/JarvusInnovations/cluster-template/tree/develop/k8s-common/grafana (via hologit) | monitoring-grafana | No     | Infrastructure |                       |
| Sentry           | Application error observability (i.e. collecting errors for investigation)                                                                                                               | https://sentry.calitp.org                      | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/sentry                       | sentry             | No                            | Infrastructure |
| JupyterHub       | Kubernetes-driven Jupyter workspace provider                                                                                                                                             | https://notebooks.calitp.org                   | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/jupyterhub                   | jupyterhub         | No                            | Analysis |


### Code and deployments (unless otherwise specified, deployments occur via GitHub Actions)

The above services are managed by code and deployed according to the following processes.

```{mermaid}
flowchart TD
%% note that you seemingly cannot have a subgraph that only contains other subgraphs
%% so I am using "label" nodes to make sure each subgraph has at least one direct child
    subgraph repos[ ]
        repos_label[GitHub repositories]
        data_infra_repo[data-infra]
        data_analyses_repo[data-analyses]
        reports_repo[reports]
    end
    subgraph kubernetes[ ]
        kubernetes_label[Google Kubernetes Engine]
        subgraph airflow[us-west2-calitp-airflow2-pr-171e4e47-gke]
            airflow_label[Production Airflow <br><i><a href='https://console.cloud.google.com/composer/environments?project=cal-itp-data-infra&supportedpurview=project'>Composer</a></i>]
            airflow_dags
            airflow_plugins
        end
        subgraph data_infra_apps_cluster[ ]
            data_infra_apps_label[data-infra-apps]
            subgraph rt_archiver[GTFS-RT Archiver]
                rt_archiver_label[<a href='https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3'>RT archiver</a>]
                prod_rt_archiver[gtfs-rt-v3 archiver]
                test_rt_archiver[gtfs-rt-v3-test archiver]
            end
            jupyterhub[<a href='https://notebooks.calitp.org'>JupyterHub</a>]
            metabase[<a href='https://dashboards.calitp.org'>Metabase</a>]
            grafana[<a href='https://monitoring.calitp.org'>Grafana</a>]
            sentry[<a href='https://sentry.calitp.org'>Sentry</a>]
        end
    end

    subgraph netlify[ ]
        netlify_label[Netlify]
        data_infra_docs[<a href='https://docs.calitp.org/data-infra'>data-infra Docs</a>]
        reports_website[<a href='https://reports.calitp.org'>California GTFS Quality Dashboard</a>]
        analysis_portfolio[<a href='https://analysis.calitp.org'>Cal-ITP Analysis Portfolio</a>]
    end

data_infra_repo --> airflow_dags
data_infra_repo --> airflow_plugins
data_infra_repo --> rt_archiver
data_infra_repo --> jupyterhub
data_infra_repo --> metabase
data_infra_repo --> grafana
data_infra_repo --> sentry

data_infra_repo --> data_infra_docs
data_analyses_repo --> jupyterhub --->|portfolio.py| analysis_portfolio
reports_repo --> reports_website

classDef default fill:white, color:black, stroke:black, stroke-width:1px
classDef group_labelstyle fill:#cde6ef, color:black, stroke-width:0px
class repos_label,kubernetes_label,netlify_label group_labelstyle
```

## Data flow

Another perspective on our architecture is the flow of each individual data type through the pipeline and into the warehouse. In general, our data ingest follows versions of this pattern:

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
Some of the key attributes of this approach:
* We generate an [`outcomes`](https://github.com/cal-itp/data-infra/blob/main/packages/calitp-data-infra/calitp_data_infra/storage.py#L418) file describing whether scrape or parse operations were successful. This makes operation outcomes visible in BigQuery, so they can be analyzed (for example: how long has the download operation for X feed been failing?)
* [External tables](https://cloud.google.com/bigquery/docs/external-data-sources#external_tables) provide the interface between ingested data and BigQuery modeling/transformations. We try to limit the amount of manipulation in Airflow `parse` tasks to the bare minimum to make the data legible to BigQuery (for example, replace illegal column names that would break the external tables.)

While many of the key elements of this architecture are common to most of our data sources, each data source has some unique aspects as well. Below are detailed overviews by data source, outlining the specific code/resources that correspond to each step in the general data flow for each main data source.

Step | Airtable | GTFS (Schedule) | GTFS (RT) | Payments (Littlepay) | Payments (Elavon)
--- | --- | --- | --- | --- | ----
Raw data source | [Airtable](https://airtable.com) | Agency-hosted URLs, defined in Airtable<sup>1</sup> | Agency-hosted URLs, defined in Airtable<sup>1</sup>  | Littlepay payment processing data | Elavon transaction data
Airflow scraper | [`airtable_ loader_v2`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/airtable_loader_v2) | [`download_gtfs_ schedule_v2`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/download_gtfs_schedule_v2) | not Airflow: [RT archiver](https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3) | [`sync_littlepay`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/sync_littlepay) | [`sync_elavon`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/sync_elavon)
Raw data bucket | [`calitp-airtable`](https://console.cloud.google.com/storage/browser/calitp-airtable;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-gtfs-schedule-raw-v2`](https://console.cloud.google.com/storage/browser/calitp-gtfs-schedule-raw-v2/schedule?project=cal-itp-data-infra&supportedpurview=project&pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-gtfs-rt-raw-v2`](https://console.cloud.google.com/storage/browser/calitp-gtfs-rt-raw-v2;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-payments-littlepay-raw`](https://console.cloud.google.com/storage/browser/calitp-payments-littlepay-raw;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-elavon-raw`](https://console.cloud.google.com/storage/browser/calitp-elavon-raw;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false)
Raw data path (wrt bucket) | One path per Airtable table (ex. `california_ transit__ organizations/`) | [`schedule/`](https://console.cloud.google.com/storage/browser/calitp-gtfs-schedule-raw-v2/schedule?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false) | One path per RT feed type (ex. `vehicle_ positions/`) | One path per data type (ex. `micropayments/`) | N/A (data in top level of bucket)
Raw data outcomes path (wrt bucket) | N/A | [`download_ schedule_ feed_results/`](https://console.cloud.google.com/storage/browser/calitp-gtfs-schedule-raw-v2/download_schedule_feed_results?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false) | N/A | [`raw_littlepay_ sync_job_ result/`](https://console.cloud.google.com/storage/browser/calitp-payments-littlepay-raw/raw_littlepay_sync_job_result?project=cal-itp-data-infra&supportedpurview=project&pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false) | N/A
Airflow parser | N/A / [`generate_gtfs_ download_ configs.py`<sup>1</sup>](https://github.com/cal-itp/data-infra/blob/main/airflow/dags/airtable_loader_v2/generate_gtfs_download_configs.py) | [`unzip_and_ validate_ gtfs_schedule_ hourly`<sup>2</sup>](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/unzip_and_validate_gtfs_schedule_hourly) | [`parse_and_ validate_rt_ v2`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/parse_and_validate_rt_v2) | [`parse_ littlepay`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/parse_littlepay) | [`parse_elavon`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/parse_elavon)
Parsed data bucket | N/A / [`calitp-gtfs-download-config`<sup>1</sup>](https://console.cloud.google.com/storage/browser/calitp-gtfs-download-config;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-gtfs-schedule-parsed-hourly`](https://console.cloud.google.com/storage/browser/calitp-gtfs-schedule-parsed-hourly;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-gtfs-rt-parsed`](https://console.cloud.google.com/storage/browser/calitp-gtfs-rt-parsed;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-payments-littlepay-parsed`](https://console.cloud.google.com/storage/browser/calitp-payments-littlepay-parsed;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-elavon-parsed`](https://console.cloud.google.com/storage/browser/calitp-elavon-parsed?project=cal-itp-data-infra&supportedpurview=project&pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false)
Parsed data path (wrt bucket) | N/A / [`gtfs_download_ configs/`<sup>1</sup>](https://console.cloud.google.com/storage/browser/calitp-gtfs-download-config/gtfs_download_configs?project=cal-itp-data-infra&pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false) | One path per file (ex. `agency/`)| One path per RT feed type (ex. `vehicle_ positions/`) | One path per data type (ex. `micropayments/`) | [`transactions/`](https://console.cloud.google.com/storage/browser/calitp-elavon-parsed/transactions?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&project=cal-itp-data-infra&supportedpurview=project&prefix=&forceOnObjectsSortingFiltering=false)
Parsed data outcomes path (wrt bucket) | N/A | One path per file (ex. `agency.txt_ parsing_results/`) | One path per RT feed type (ex. `vehicle_ positions_ outcomes/`) | [`parse_ littlepay_ job_result/`](https://console.cloud.google.com/storage/browser/calitp-payments-littlepay-parsed/parse_littlepay_job_result) | N/A
Airflow validator | N/A (not GTFS) | [`unzip_and_ validate_ gtfs_schedule_ hourly`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/unzip_and_validate_gtfs_schedule_hourly) | [`parse_and_ validate_rt_ v2`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/parse_and_validate_rt_v2) | N/A (not GTFS) | N/A (not GTFS)
Validations data bucket | N/A (not GTFS) | [`calitp-gtfs-schedule-validation`](https://console.cloud.google.com/storage/browser/calitp-gtfs-schedule-validation;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&prefix=&forceOnObjectsSortingFiltering=false) | [`calitp-gtfs-rt-validation`](https://console.cloud.google.com/storage/browser/calitp-gtfs-rt-validation;tab=objects?forceOnBucketsSortingFiltering=true&project=cal-itp-data-infra&prefix=&forceOnObjectsSortingFiltering=false) | N/A (not GTFS) | N/A (not GTFS)
Validations data path (wrt bucket) | N/A (not GTFS) | [`validation_notices/`](https://console.cloud.google.com/storage/browser/calitp-gtfs-schedule-validation/validation_notices?project=cal-itp-data-infra&pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false) | One per GTFS RT feed type (ex. `vehicle_ positions_ validation_ notices/`) | N/A (not GTFS) | N/A (not GTFS)
Validation outcomes data path (wrt bucket) | N/A (not GTFS) | [`validation_ job_results/`](https://console.cloud.google.com/storage/browser/calitp-gtfs-schedule-validation/validation_job_results?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&project=cal-itp-data-infra&prefix=&forceOnObjectsSortingFiltering=false) | One per GTFS RT feed type (ex. `vehicle_ positions_ validation_ outcomes/`) | N/A (not GTFS) | N/A (not GTFS)
Airflow [create external tables](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/create_external_tables) | [airtable](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/create_external_tables/airtable) | [gtfs_scheduled_v2](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/create_external_tables/gtfs_schedule_v2) | [gtfs_rt_v2](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/create_external_tables/gtfs_rt_v2) | [payments/littlepay](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/create_external_tables/payments/littlepay) | [payments/elavon](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/create_external_tables/payments/elavon)
External tables dataset | [`external_ airtable`](https://dbt-docs.calitp.org/#!/source_list/airtable#details) | [`external_ gtfs_schedule`](https://dbt-docs.calitp.org/#!/source_list/external_gtfs_schedule) | [`external_ gtfs_rt_v2`](https://dbt-docs.calitp.org/#!/source_list/external_gtfs_rt) | [`external_ littlepay`](https://dbt-docs.calitp.org/#!/source_list/external_littlepay) | [`external_ elavon`](https://dbt-docs.calitp.org/#!/source_list/elavon_external_tables)
dbt | See [dbt docs](https://dbt-docs.calitp.org/#!/overview) | See [dbt docs](https://dbt-docs.calitp.org/#!/overview) | See [dbt docs](https://dbt-docs.calitp.org/#!/overview) | See [dbt docs](https://dbt-docs.calitp.org/#!/overview) | See [dbt docs](https://dbt-docs.calitp.org/#!/overview)

<sup>1</sup> The GTFS Schedule and GTFS RT pipelines get their lists of URLs to scrape from the `gtfs datasets.pipeline uri` and associated authentication fields in Airtable. To facilitate this, there is a special Airflow task to generate what we call `GTFS download config` files, which are like a special type of parsed Airtable file that is designed for consumption into GTFS download processes rather than BigQuery external tables.

<sup>2</sup> For GTFS schedule data, "parsing" is broken into two steps: unzipping the raw zipfile, and then parsing the contents of that zipfile (where parsing means taking the original CSV and converting to JSONL format). This table lists only the `parsed` buckets for simplicity but technically there is an additional step.



## Environments
### production
* Managed Airflow (i.e. Google Cloud Composer)
* Production gtfs-rt-archiver-v3
* `cal-itp-data-infra` database (i.e. project) in BigQuery
* Google Cloud Storage buckets _without_ a prefix
    * e.g. `gs://calitp-gtfs-schedule-parsed-hourly`


### testing/staging/dev
* Locally-run Airflow (via docker-compose)
* Test gtfs-rt-archiver-v3
* `cal-itp-data-infra-staging` database (i.e. project) in BigQuery
* GCS buckets with the `test-` prefix
    * e.g. `gs://test-calitp-gtfs-rt-raw-v2`
    * Some buckets prefixed with `dev-` also exist; primarily for testing the RT archiver locally
