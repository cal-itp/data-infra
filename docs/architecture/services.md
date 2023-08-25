# Deployed services

Here is a list of services that are deployed as part of the Cal-ITP project.

| Name             | Function                                                                                                                                                                                 | URL                                            | Source code                                                                                         | K8s namespace      | Development/test environment? | Type?                      |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------ | ----------------------------- | -------------------------- |
| Airflow          | General orchestation/automation platform; downloads non-GTFS Realtime data and orchestrates data transformations outside of dbt; executes stateless jobs such as dbt and data publishing | https://o1d2fa0877cf3fb10p-tp.appspot.com/home | https://github.com/cal-itp/data-infra/tree/main/airflow                                             | n/a                | Yes (local)                   | Infrastructure / Ingestion |
| GTFS-RT Archiver | Downloads GTFS Realtime data (more rapidly than Airflow can handle)                                                                                                                      | n/a                                            | https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3                        | gtfs-rt-v3         | Yes (gtfs-rt-v3-test)         | Ingestion                  |
| Metabase         | Web-hosted BI tool                                                                                                                                                                       | https://dashboards.calitp.org                  | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/metabase                     | metabase           | Yes (metabase-test)           | Analysis                   |
| Grafana          | Application observability (i.e. monitoring and alerting on metrics)                                                                                                                      | https://monitoring.calitp.org                  | https://github.com/JarvusInnovations/cluster-template/tree/develop/k8s-common/grafana (via hologit) | monitoring-grafana | No                            | Infrastructure             |
| Sentry           | Application error observability (i.e. collecting errors for investigation)                                                                                                               | https://sentry.calitp.org                      | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/sentry                       | sentry             | No                            | Infrastructure             |
| JupyterHub       | Kubernetes-driven Jupyter workspace provider                                                                                                                                             | https://notebooks.calitp.org                   | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/jupyterhub                   | jupyterhub         | No                            | Analysis                   |

## Code and deployments (unless otherwise specified, deployments occur via GitHub Actions)

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
