(architecture-overview)=

# Architecture Overview

The Cal-ITP data infrastructure facilitates several types of data workflows:

- `Ingestion`
- `Modeling/transformation`
- `Analysis`

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

This documentation outlines two ways to think of this system and its components from a technical/maintenance perspective:

- [Services](services) that are deployed and maintained (ex. Metabase, JupyterHub, etc.)
- [Data pipelines](data) to ingest specific types of data (ex. GTFS Schedule, Payments, etc.)

Outside of this documentation, several READMEs cover initial development environment setup for new users. The [/warehouse README](https://github.com/cal-itp/data-infra/blob/main/warehouse) and the [/airflow README](https://github.com/cal-itp/data-infra/blob/main/airflow) in the Cal-ITP data-infra GitHub repository are both essential starting points for getting up and running as a contributor to the Cal-ITP code base. The [repository-level README](https://github.com/cal-itp/data-infra) covers some important configuration steps and social practices for contributors.

NOTE: sections of the /warehouse README discussing installation and use of JupyterHub are likely to be less relevant to infrastructure, pipeline, package, image, and service development than they are for analysts who work primarily with tables in the warehouse - most contributors performing "development" work on Cal-ITP tools and infrastructure use a locally installed IDE like VS Code rather than relying on the hosted JupyterHub environment for that work, since that environment is tailored to analysis tasks and is somewhat limited for development and testing tasks. Some documentation on this site and in the repository has a shared audience of developers and analysts, and as such you can expect that documentation to make occasional reference to JupyterHub even if it's not a core requirement for the type of work being discussed.

## Environments

Across both data and services, we often have a "production" (live, end-user-facing) environment and some type of testing, staging, or development environment.

### production

- Managed Airflow (i.e. Google Cloud Composer)
- Production gtfs-rt-archiver-v3
- `cal-itp-data-infra` database (i.e. project) in BigQuery
- Google Cloud Storage buckets _without_ a prefix
  - e.g. `gs://calitp-gtfs-schedule-parsed-hourly`

### testing/staging/dev

- Locally-run Airflow (via docker-compose)
- Test gtfs-rt-archiver-v3
- `cal-itp-data-infra-staging` database (i.e. project) in BigQuery
- GCS buckets with the `test-` prefix
  - e.g. `gs://test-calitp-gtfs-rt-raw-v2`
  - Some buckets prefixed with `dev-` also exist; primarily for testing the RT archiver locally
