# gtfs-rt-parser

This image packages code to parse GTFS RT protobufs into newline-delimited JSON for querying
via BigQuery external tables. This is primarily so we can run this code as a PodOperator on
a special jobs node pool; if we ever self-host Airflow and use the [KubernetesExecutor](https://airflow.apache.org/docs/apache-airflow/stable/executor/kubernetes.html), this
separate image will be redundant.

# gtfs-rt-validator-api

This is basically a ground-up refactor of https://github.com/cal-itp/gtfs-rt-validator-api. It aggregates
data to hourly, so we can fit within BigQuery external table file count limits. It also combines parsing
and validating in the same codebase, controlled by CLI flags. Much of RT parsing and validation overlaps
(downloading RT files, processing in some way, uploading aggregated results) so it just made sense to
combine them.

## Testing
This image can be built and tested via local Airflow.

In addition, there is at least one Python test that can be executed via `poetry run pytest`.
