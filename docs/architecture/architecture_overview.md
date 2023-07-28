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
airflow_external_tables{<b>Airflow</b>: <br> create<br>external tables}
dbt([<b>dbt</b>])
airflow_dbt{<b>Airflow</b>: <br> run dbt}

subgraph first_bq[ ]
    bq_label1[BigQuery<br>External tables dataset]
    ext_raw_outcomes[(Scrape outcomes<br>external table)]
    ext_parse_data[(Parsed data<br>external table)]
    ext_parse_outcomes[(Parse outcomes<br>external table)]
end

subgraph second_bq[ ]
    bq_label2[BigQuery<br>Staging, mart, etc. datasets]
    bq_table_example[(Example table 1)]
    bq_table_example2[(Example table 2)]
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

raw_data -- read by--> airflow_scrape
airflow_scrape -- writes data to--> raw_gcs
airflow_scrape -- writes operation outcomes to--> raw_outcomes_gcs
raw_gcs -- read by--> airflow_parse
airflow_parse -- writes data to--> parse_gcs
airflow_parse -- writes operation outcomes to--> parse_outcomes_gcs

parse_outcomes_gcs -- external tables  defined by--> airflow_external_tables
parse_gcs -- external tables  defined by--> airflow_external_tables
raw_outcomes_gcs -- external tables  defined by--> airflow_external_tables


airflow_external_tables -- defines--> ext_raw_outcomes
airflow_external_tables -- defines--> ext_parse_data
airflow_external_tables -- defines--> ext_parse_outcomes

airflow_dbt -- runs--> dbt
first_bq -- read as sources by-->dbt

dbt -- orchestrates transformations to create-->second_bq

classDef default fill:white, color:black, stroke:black, stroke-width:1px

classDef gcs_group_boxstyle fill:lightblue, color:black, stroke:black, stroke-width:1px

classDef bq_group_boxstyle fill:lightgreen, color:black, stroke:black, stroke-width:1px

classDef raw_datastyle fill:yellow, color:black, stroke:black, stroke-width:1px

classDef dbtstyle fill:darkgreen, color:white, stroke:black, stroke-width:1px

classDef group_labelstyle fill:lightgray, color:black, stroke-width:0px

class raw_data raw_datastyle
class dbt dbtstyle
class first_gcs,second_gcs gcs_group_boxstyle
class first_bq,second_bq bq_group_boxstyle
class gcs_label1,gcs_label2,bq_label1,bq_label2 group_labelstyle
```
Some of the key attributes of this approach:
* We generate an [`outcomes`](https://github.com/cal-itp/data-infra/blob/main/packages/calitp-data-infra/calitp_data_infra/storage.py#L418) file describing whether scrape or parse operations were successful. This makes operation outcomes visible in BigQuery, so they can be analyzed (for example: how long has the download operation for X feed been failing?)
* [External tables](https://cloud.google.com/bigquery/docs/external-data-sources#external_tables) provide the interface between ingested data and BigQuery modeling/transformations. We try to limit the amount of manipulation in Airflow `parse` tasks to the bare minimum to make the data legible to BigQuery (for example, replace illegal column names that would break the external tables.)

While many of the key elements of this architecture are common to most of our data sources, each data source has some unique aspects as well. Below are detailed overviews over each data source and its ingest considerations.

### Airtable

Airtable data is ingested as follows:

```{mermaid}
flowchart TD

airflow[Airflow task: <a href='https://github.com/cal-itp/data-infra/tree/main/airflow/dags/airtable_loader_v2'>airtable_loader_v2</a>]

raw_bucket[Raw data bucket: <a href='https://console.cloud.google.com/storage/browser/calitp-airtable'>calitp-airtable</a>]

classDef default fill:white, color:black, stroke:black, stroke-width:1px
```



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
