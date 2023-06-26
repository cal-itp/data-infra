(architecture-overview)=
# Architecture Overview

Deployed services (unless otherwise specified, deployments occur via GitHub Actions)
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
