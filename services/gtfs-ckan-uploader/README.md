# GTFS CKAN Uploader

This service is currently just a script that can upload our current GTFS Schedule Data
to data.ca.gov.

## Installation

```
pip install calitp requests
```

## Running script

From this directory, set the CKAN API key with the following code.

```
export CALITP_CKAN_GTFS_SCHEDULE_KEY=<SOME_API_KEY>
```

Then, run the export script below.

python calitp_data_ca_exporter.py
```
