# gtfs-rt-parser

This script parses GTFS RT protobufs into newline-delimited JSON for querying
via BigQuery external tables. This script aggregates data hourly, so we can fit
within BigQuery external table file count limits.


## Running automated tests

1. Install poetry dependencies for airflow:

```bash
$ poetry install
```

2. Run gtfs-rt-parser tests:

```bash
$ poetry run pytest tests/scripts/test_gtfs_rt_parser.py
```

To run only a specific test, you can reference like this:

```bash
$ poetry run pytest tests/scripts/test_gtfs_rt_parser.py::TestGtfsRtParser::test_no_vehicle_positions_for_date
```


## GTFS-RT Validator JAR file

The `gtfs-realtime-validator-lib-x.y.z-yyyymmdd.HHMMss-v.jar` is an old snapshot
of the GTFS Realtime validator that now lives under
[MobilityData](https://github.com/MobilityData/gtfs-realtime-validator).
We've vendored an old version to help make our builds less dependent on external
services. We should begin using the officially-published
[packages](https://github.com/orgs/MobilityData/packages?repo_name=gtfs-realtime-validator)
at some point in the future.
