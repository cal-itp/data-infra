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

This documentation outlines two ways to think of this system and its components from a technical/maintenance perspective:
* [Services](services) that are deployed and maintained (ex. Metabase, JupyterHub, etc.)
* [Data pipelines](data) to ingest specific types of data (ex. GTFS Schedule, Payments, etc.)

## Environments

Across both data and services, we often have a "production" (live, end-user-facing) environment and some type of testing, staging, or development environment.

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
