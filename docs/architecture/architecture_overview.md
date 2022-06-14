(architecture-overview)=
# Architecture Overview
Here is a high-level summary of the Cal-ITP data services architecture.

```{mermaid}
flowchart TD
%% note that you seemingly cannot have a subgraph that only contains other subgraphs
%% so I am using "label" nodes to make sure each subgraph has at least one direct child
    subgraph key[Key]
        empty3[ ]--Manual-->empty4[ ]
        test[Test/staging/dev]
    end
    subgraph data_sources[ ]
        data_sources_label[Data Sources]
        raw_gtfs[Raw GTFS schedule data]
        airtable[<a href='https://airtable.com/'>Airtable</a>]
        raw_payment[Raw fare payment]
        raw_rt[Raw GTFS RT feeds]
    end
    subgraph airflow[ ]
        airflow_label[Airflow]
        airflow_prod[Production Airflow <br><i><a href='https://console.cloud.google.com/composer/environments?project=cal-itp-data-infra&supportedpurview=project'>Composer</a></i>]
        airflow_local[Local Airflow <br><i><a href='https://github.com/cal-itp/data-infra/blob/main/airflow/README.md'>Setup</a></i>]
    end
    subgraph data_storage[ ]
        data_storage_label[Data Storage]
        subgraph bq[<a href='https://console.cloud.google.com/bigquery'>BigQuery</a> - projects]
            bq_prod[BigQuery prod project]
            bq_stage[BigQuery staging project]
        end
        subgraph gcs[<a href='https://console.cloud.google.com/storage/browser'>GCS</a> - buckets]
            gcs_other[Metabase, GCP logs, etc.]
            gcs_payment[Payment buckets]
            gcs_gtfs[gtfs-data]
            gcs_gtfs_test[gtfs-data-test]
        end
    end
    subgraph rt_archiver[ ]
        rt_archiver_label[<a href='https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archive'>RT archiver</a>]
        prod_rt_archiver[Prod archiver]
        prepod_rt_archiver[Preprod archiver]
    end
    subgraph reports[ ]
        reports_label[Reports]
        reports_website[<a href='https://reports.calitp.org'>reports.calitp.org</a>]
    end
    subgraph docs[ ]
        docs_label[Docs]
        docs_website[<a href='https://docs.calitp.org'>docs.calitp.org</a>]
    end
    subgraph analysis_tools[ ]
        analysis_tools_label[Analysis]
        jupyterhub[<a href='https://hubtest.k8s.calitp.jarv.us/hub/'>JupyterHub</a>]
        metabase[<a href='https://dashboards.calitp.org/'>Metabase - dashboards.calitp.org</a>]
    end
%% links from data sources
raw_payment --> data_transfer[Data Transfer]
raw_rt --> rt_archiver
raw_gtfs --> airflow
airtable --> airflow
raw_gtfs -.-> schedule_validator
raw_gtfs -.-> rt_validator
raw_rt -.-> rt_validator
%% links from data storage
bq --> metabase
bq --> jupyterhub
bq --> reports
gcs <--> jupyterhub
%% links from ungrouped items
data_transfer --> gcs
rt_archiver --> gcs
airflow <--> data_storage
airflow --> schedule_validator[GTFS Schedule validator  <br> <i>externally maintained</i>]
airflow --> rt_validator[GTFS RT validator <br> <i>externally maintained</i>]
schedule_validator --> gcs
rt_validator --> gcs
%% define styles
classDef default fill:white, color:black, stroke:black, stroke-width:1px
%% yellow for testing / staging versions
classDef teststyle fill:#fdfcd8, color:#000000
%% styling for groups & their labels
classDef group_labelstyle fill:#cde6ef, color:black, stroke-width:0px
%% styling for subgroups
classDef subgroupstyle fill:#14A6E0, color:white
%% styling for the key
classDef keystyle fill:#1e1e19, color: white
%% apply test styles
class prepod_rt_archiver,bq_stage,gcs_gtfs_test,airflow_local,test teststyle
%% apply label styles
class data_storage_label,data_sources_label,reports_label,docs_label,analysis_tools_label,airflow_label,rt_archiver_label group_labelstyle
%% apply group styles
class data_storage,data_sources,reports,docs,analysis_tools,airflow,rt_archiver group_labelstyle
%% apply subgroup styles
class gcs,bq subgroupstyle
%% style the key
class key keystyle
%% default arrow style
linkStyle default stroke:black, stroke-width:4px
%% manual connection arrow style
linkStyle 0,9,10,11 stroke:orange, stroke-width:4px
```

## “Production environment”

The "production" ("prod") environment consists of:
* RT Archiver
* Airflow as run through Composer
* `cal-itp-data-infra` project in Google Cloud Platform (BigQuery and Google Cloud Storage)
    * Specifically, the `gtfs-data` and `littlepay-data-extract-prod` buckets in Google Cloud Storage


## “Testing environment”
The "testing"/"staging"/"dev" environment consists of:
* RT Archiver pre-prod
* Airflow as run locally
* `cal-itp-data-infra-staging` project in BigQuery
    * Note that this project also exists in Google Cloud Storage (since it's a Google Cloud Platform project) but it is not used in GCS
* The `gtfs-data-test` bucket in Google Cloud Storage (which is inside the *production* `cal-itp-data-infra` *project*)

## Airflow data production:
* Downloads GTFS Schedule data
* Consumes raw RT data and produces parsed RT data
* Runs the validators to produce validation data for both Schedule and RT

## Airflow data consumption:
* Consumes raw Schedule and RT data
* Consumes BigQuery data for job configuration

## BigQuery data consumption:
* Reads GCS -- see the [Querying Cloud Storage data](https://cloud.google.com/bigquery/external-data-cloud-storage) documentation

## BigQuery data production:
* Some tables are read by Airflow for job configuration (for example, `gtfs_schedule_history.calitp_feed_status`)
