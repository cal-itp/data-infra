# gtfs-rt-parser

This image packages code to parse GTFS RT protobufs into newline-delimited JSON for querying
via BigQuery external tables. This is primarily so we can run this code as a PodOperator on
a special jobs node pool; if we ever self-host Airflow and use the [KubernetesExecutor](https://airflow.apache.org/docs/apache-airflow/stable/executor/kubernetes.html), this
separate image will be redundant.

# gtfs-rt-validator-api

This is basically a ground-up refactor of https://github.com/cal-itp/gtfs-rt-validator-api.

## Testing
This image can be built and tested via local Airflow.

In addition, there is at least one Python test that can be executed via `poetry run pytest`.
