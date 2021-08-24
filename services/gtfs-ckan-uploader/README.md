# GTFS CKAN Uploader

This service is currently just a script that can upload our current GTFS Schedule Data
to data.ca.gov.

## Installation

```python
pip install calitp requests
```

## Running script

From this directory, set the CKAN API key with the following code.

```bash
export CALITP_CKAN_GTFS_SCHEDULE_KEY=<SOME_API_KEY>
```

Then, run the export script below.

```python
python calitp_data_ca_exporter.py
```

Note that the script runs a number requests. You can pull out a URL from the request response that let's you download the data.

E.g.

```
curl -H "Authorization: <SOME_API_KEY>"  "https://data.ca.gov/dataset/de6f1544-b162-4d16-997b-c183912c8e62/resource/c6bbb637-988f-431c-8444-aef7277297f8/download/gtfs_schedule_routes.csv"
```
