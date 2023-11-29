# calitp-data-infra

Library for sharing data pipeline functionality across Airflow and pod
operators. In general, we store files in GCS using subclasses of
PartitionedGCSArtifact which handles saving files (as bytes) to hive-partitioned
locations and serializing the object attributes as metadata JSON on the
resulting storage object. This module also contains functions for downloading
GTFS feeds based on a GTFSDownloadConfig and is used by both the GTFS Schedule
download Airflow DAG and the GTFS RT archiver.
