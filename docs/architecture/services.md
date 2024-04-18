# Deployed Services and Sites

Many services and websites are deployed as part of the Cal-ITP ecosystem, maintained directly by Cal-ITP contributors and orchestrated via Google Kubernetes Engine or published via Netlify or GitHub Pages.

With the exception of Airflow, which is [managed via Google Cloud Composer](https://github.com/cal-itp/data-infra/tree/main/airflow#upgrading-airflow-itself), changes to the services discussed here are deployed via CI/CD processes that run automatically when new code is merged to the relevant Cal-ITP repository. These CI/CD processes are not all identical - different services have different testing steps that run when a pull request is opened against the services's code. Some services undergo a full test deployment when a PR is opened, some report the changes that a subject [Helm chart](https://helm.sh/docs/topics/charts/) will undergo upon merge, and some just perform basic linting.

READMEs describing the individual testing and deployment process for each service are linked in the below table, and [the CI README](https://github.com/cal-itp/data-infra/tree/main/ci/README.md) provides some more general context for Kubernetes-based deployments. Many services are monitored via Sentry, discussed in [a later section](#monitoring-running-services).

| Name              | Function                                                                                                                                                                                 | URL                                                                                       | Source code and README (if present)                                                                 | K8s namespace      | Development/test environment?    | Service Type                   |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------ | -------------------------------- | ------------------------------ |
| Airflow           | General orchestation/automation platform; downloads non-GTFS Realtime data and orchestrates data transformations outside of dbt; executes stateless jobs such as dbt and data publishing | https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/home | https://github.com/cal-itp/data-infra/tree/main/airflow                                             | n/a                | Yes (local)                      | Infrastructure / Ingestion     |
| BigQuery          | Data warehouse used for data modeling and analysis (managed via Google Cloud Composer)                                                                                                   | https://console.cloud.google.com/bigquery?project=cal-itp-data-infra                      | https://github.com/cal-itp/data-infra/tree/main/warehouse (infra managed via Google Cloud Composer) | n/a                | Yes (cal-itp-data-infra-staging) | Infrastructure                 |
| Cal-ITP Docs Site | Public-facing documentation for various Cal-ITP repositories, services, and related technical resources                                                                                  | https://docs.calitp.org                                                                   | https://github.com/cal-itp/data-infra/tree/main/docs                                                | n/a                | Yes (Netlify deploy on PRs)      | Documentation                  |
| Dask              | Parallelization infrastructure used by JupyerHub and Prometheus                                                                                                                          | n/a                                                                                       | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/dask                         | dask               | No                               | Infrastructure                 |
| Grafana           | Application observability (i.e. monitoring and alerting on metrics)                                                                                                                      | https://monitoring.calitp.org                                                             | https://github.com/JarvusInnovations/cluster-template/tree/develop/k8s-common/grafana (via hologit) | monitoring-grafana | No                               | Infrastructure                 |
| GTFS-RT Archiver  | Downloads GTFS Realtime data (more rapidly than Airflow can handle)                                                                                                                      | n/a                                                                                       | https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3                        | gtfs-rt-v3         | Yes (gtfs-rt-v3-test)            | Ingestion                      |
| JupyterHub        | Kubernetes-driven Jupyter workspace provider                                                                                                                                             | https://notebooks.calitp.org                                                              | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/jupyterhub                   | jupyterhub         | No                               | Analysis                       |
| Metabase          | Web-hosted BI tool                                                                                                                                                                       | https://dashboards.calitp.org                                                             | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/metabase                     | metabase           | Yes (metabase-test)              | Analysis                       |
| Netlify           | Web publishing infrastructure for Cal-ITP Analysis Portfolio, dbt docs site, and California GTFS Quality Dashboard, managed via GitHub interface                                         | TODO                                                                                      | Varies by specific deployed site (infra managed via Netlify GitHub interface)                       | n/a                | Yes (varies by deployed site)    | Documentation / Infrastructure |
| Sentry            | Application error observability (i.e. collecting errors for investigation)                                                                                                               | https://sentry.calitp.org                                                                 | https://github.com/cal-itp/data-infra/tree/main/kubernetes/apps/charts/sentry                       | sentry             | No                               | Infrastructure                 |

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
        subgraph airflow[us-west2-calitp-airflow2-pr-88ca8ec6-gke]
            airflow_label[Production Airflow <br><i><a href='https://console.cloud.google.com/composer/environments?project=cal-itp-data-infra&supportedpurview=project'>Composer</a></i>]
            airflow_dags
            airflow_plugins
        end
        subgraph data_infra_apps_cluster[data-infra-apps]
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
        reports_website[<a href='https://reports.calitp.org'>California GTFS Quality Dashboard</a>]
        analysis_portfolio[<a href='https://analysis.calitp.org'>Cal-ITP Analysis Portfolio</a>]
    end

    subgraph github_pages[ ]
        github_pages_label[GitHub Pages]
        data_infra_docs[<a href='https://docs.calitp.org/data-infra'>data-infra Docs</a>]
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
class repos_label,kubernetes_label,netlify_label,github_pages_label group_labelstyle
```

## Monitoring running services

### Error monitoring through Sentry

A subset of our services and sites send error information to the Cal-ITP Sentry instance, which groups errors based on criteria we define in order to identify and track new errors, regressions, and intermittent service issues. A runbook is available [here](https://github.com/cal-itp/data-infra/blob/main/runbooks/workflow/sentry-triage.md) which discusses daily triage of events logged in Sentry, and general documentation for self-hosted instances of Sentry like ours is available [here](https://develop.sentry.dev/self-hosted/).

### Cost and performance monitoring

In addition to standard Google Cloud tooling for monitoring specific services like Kubernetes Enginer, Composer, and BigQuery, we maintain a couple dashboards that can make it easier to glean at-at-glance insights and report topline information to stakeholders who don't have the time, access, or knowledge to dig into GCP monitoring directly.

The [BigQuery overview dashboard](https://dashboards.calitp.org/dashboard/76-bigquery-overview-dashboard?principal_email_substring=&time_window=past7days) gives a detailed view of daily and monthly BigQuery costs, and helps identify tables and dbt models that are producing greater build costs, reference costs, and query costs than others.

In a prior staffing configuration, a person was assigned to fill the [Cal-ITP System Performance and Outcomes Monitoring dashboard](https://dashboards.calitp.org/dashboard/138-cal-itp-system-performance-and-outcomes-monitoring?single_date=2023-06-22) and use it to populate the metrics in the spreadsheet linked within the dashboard each Friday. Checks were recommended to occur on Fridays because for one of the metrics, Google auto-bins 7 day periods to Friday-Thursday. This dashboard and spreadsheet could be re-activated if desired.
