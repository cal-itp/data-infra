# calitp-data-infra

Library for sharing data pipeline functionality across Airflow and pod
operators. In general, we store files in GCS using subclasses of
PartitionedGCSArtifact which handles saving files (as bytes) to hive-partitioned
locations and serializing the object attributes as metadata JSON on the
resulting storage object. This module also contains functions for downloading
GTFS feeds based on a GTFSDownloadConfig and is used by both the GTFS Schedule
download Airflow DAG and the GTFS RT archiver.

## Testing and publishing
This repository should pass mypy and other static checkers, and has a small
number of tests. These checks are executed in [GiHub Actions](../../.github/workflows/build-calitp-data-infra.yml) and the package will
eventually be published to pypi on merge.
