(architecture-overview)=
# Architecture Overview

## Deployed services

| Name             | Function                                                                                                                                                                                 | URL                                            | Source code                                                                                         | K8s namespace      | Development/test environment? |
|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|-----------------------------------------------------------------------------------------------------|--------------------|-------------------------------|
| Airflow          | General orchestation/automation platform; downloads non-GTFS Realtime data and orchestrates data transformations outside of dbt; executes stateless jobs such as dbt and data publishing | https://o1d2fa0877cf3fb10p-tp.appspot.com/home | https://github.com/cal-itp/data-infra/tree/main/airflow                                             | n/a                | Yes (local)                   |
| GTFS-RT Archiver | Downloads GTFS Realtime data (more rapidly than Airflow can handle)                                                                                                                      | n/a                                            | https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3                        | gtfs-rt-v3         | Yes (gtfs-rt-v3-test)         |
| Metabase         | Web-hosted BI tool                                                                                                                                                                       | https://dashboards.calitp.org                  | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/metabase                     | metabase           | Yes (metabase-test)           |
| Grafana          | Application observability (i.e. monitoring and alerting on metrics)                                                                                                                      | https://monitoring.calitp.org                  | https://github.com/JarvusInnovations/cluster-template/tree/develop/k8s-common/grafana (via hologit) | monitoring-grafana | No                            |
| Sentry           | Application error observability (i.e. collecting errors for investigation)                                                                                                               | https://sentry.calitp.org                      | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/sentry                       | sentry             | No                            |
| JupyterHub       | Kubernetes-driven Jupyter workspace provider                                                                                                                                             | https://notebooks.calitp.org                   | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/jupyterhub                   | jupyterhub         | No                            |


## Code and deployments (unless otherwise specified, deployments occur via GitHub Actions)
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
* Dotted lines indicate data flow from external (i.e. non-Cal-ITP) sources, such as agency-hosted GTFS feeds
* Orange lines indicate manual data flows, such as an analyst executing a Jupyter notebook
* Yellow nodes indicate testing/development environments
```{mermaid}
flowchart LR
%% default styles
classDef default fill:white, color:black, stroke:black, stroke-width:1px
linkStyle default stroke:black, stroke-width:4px
classDef test fill:#fdfcd8, color:#000000
classDef group fill:#cde6ef, color:black, stroke-width:0px
classDef subgroup fill:#14A6E0, color:white

%% note that you seemingly cannot have a subgraph that only contains other subgraphs
%% so I am using "label" nodes to make sure each subgraph has at least one direct child
subgraph sources[ ]
    data_sources_label[Data Sources]:::group
    raw_gtfs[Raw GTFS schedule data]
    airtable[<a href='https://airtable.com/'>Airtable</a>]
    raw_payment[Raw fare payment]
    raw_rt[Raw GTFS RT feeds]
end
subgraph rt_archiver[ ]
    rt_archiver_label[<a href='https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3'>RT archiver</a>]:::group
    prod_rt_archiver[Prod archiver]
    test_rt_archiver[Test archiver]:::test
end
subgraph airflow[ ]
    airflow_label[Airflow]:::group
    airflow_prod[Production Airflow <br><i><a href='https://console.cloud.google.com/composer/environments?project=cal-itp-data-infra&supportedpurview=project'>Composer</a></i>]
    airflow_local[Local Airflow <br><i><a href='https://github.com/cal-itp/data-infra/blob/main/airflow/README.md'>Setup</a></i>]:::test
end
subgraph gcp[Google Cloud Project]
    subgraph bigquery[<a href=''>BigQuery</a>]
        bq_cal_itp_data_infra[(cal-itp-data-infra)]
        bq_cal_itp_data_infra_staging[(cal-itp-data-infra-staging)]:::test
    end
    subgraph gcs[<a href='https://console.cloud.google.com/storage/browser'>Google Cloud Storage</a>]
        gcs_raw[(Raw)]
        gcs_parsed[(Parsed)]
        gcs_validation[(Validation)]
        gcs_analysis[(Analysis artifacts)]
        gcs_map_tiles[(Map tiles/GeoJSON)]
        gcs_other[(Backups, Composer code, etc.)]
        gcs_test[(test-* buckets)]:::test
    end
end

subgraph consumers[ ]
    consumers_label[Data consumers]:::group
    jupyterhub[<a href='https://hubtest.k8s.calitp.jarv.us/hub/'>JupyterHub</a>]
    metabase[<a href='https://dashboards.calitp.org/'>Metabase - dashboards.calitp.org</a>]
    reports_website[<a href='https://reports.calitp.org'>reports.calitp.org</a>]
end

%% subgraphs cannot be styled in-line
class sources,rt_archiver,airflow,gcp,consumers group

%% manual actions; put first for easier style indexing
%% add indices to linkStyle as new manual connections exist
jupyterhub --> gcs_analysis
jupyterhub --> gcs_map_tiles
linkStyle 0,1 stroke:orange, stroke-width:4p

%% data sources and transforms
raw_gtfs -.-> airflow
airtable --> airflow
raw_payment -.-> airflow
airflow_prod ---> gcs_raw
airflow_local ---> gcs_test
raw_rt -.-> prod_rt_archiver --> gcs_raw
raw_rt -.-> test_rt_archiver --> gcs_test
%% data transformations
gcs_raw -->|<a href='https://github.com/MobilityData/gtfs-validator'>GTFS Schedule validator</a>| gcs_validation
gcs_raw -->|<a href='https://github.com/MobilityData/gtfs-realtime-validator'>GTFS-RT validator</a>| gcs_validation
gcs_raw -->|"GTFS Schedule, RT, Payments, etc. parsing jobs"| gcs_parsed

%% data consumption
gcs_parsed --> bigquery
gcs_validation --> bigquery
bigquery --> consumers
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
