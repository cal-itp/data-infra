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

## The GTFS-RT validator

The [validator jar](./rt-validator.jar) is an old snapshot of the GTFS Realtime validator that now lives under
[MobilityData](https://github.com/MobilityData/gtfs-realtime-validator). We've temporarily vendored an old version
(specifically "1.0.0-SNAPSHOT") to help make our builds less dependent on external services. We should begin
using the officially-published [packages](https://github.com/orgs/MobilityData/packages?repo_name=gtfs-realtime-validator) at some point in the future.
