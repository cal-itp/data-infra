# gtfs-rt-archive

## Quickstart

See dependencies section below for details on prerequisites

```bash
export CALITP_LOG_LEVEL=debug
export CALITP_DATA_DEST=gs://gtfs-data/rt
export CALITP_DATA_DEST_SECRET=$HOME/Downloads/cal-itp-data-infra-661571285e30.json
export CALITP_AGENCIES_YML=$HOME/Downloads/data_agencies.yml
export CALITP_HEADERS_YML=$HOME/Downloads/data_headers.yml
python services/gtfs-rt-archive/gtfs-rt-archive.py
```

## Dependencies

### python

See `services/gtfs-rt-archive/Dockerfile` for an authoritative list of required pyhon libraries

### GCP service account

A service account with privileges to upload to `CALITP_DATA_DEST` is required, and a
[service account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#iam-service-account-keys-create-console)
for the account must be downloaded to the local filesystem. The `CALITP_DATA_DEST_SECRET` environment variable must point to the
filesystem location of the downloaded key.

### agencies data

A copy of an agencies data file (available at gs://us-west2-calitp-airflow-pro-332827a9-bucket/data/agencies.yml) must be downloaded to the local
filesystem. The `CALITP_AGENCIES_YML` environment variable must point to the filesystem location of the downloaded data file.

### header data

Additional HTTP Headers can be provided in the yaml file specified in the `CALITP_HEADERS_YML` env variable. This file should be a list of
objects specifying the `headers-data` (headers to be applied to each request) and the URLs (a map indicating which urls the headers apply to).
If duplicate headers are specified for a url (matched via `f'{itp_id}/{url_number}/{rt_url}`), a value error will be thrown when parsing the
header data file.

Also, secret values can be substituted at build time using `{{ DOUBLE_BRACES }}` as in the example below. These secret values are built from
airtable and are shared with the `CALITP_AGENCIES_YML` file.

```yaml
- header-data:
    authorization: {{ SWIFTLY_AUTHORIZATION_KEY }}
    content-type: application/json
  URLs:
    - itp_id: 123 # itp_id specified in the agencies.yml file
      url_number: 0 # index in the feeds list
      rt_urls: # url keys of the feed
        - gtfs_rt_vehicle_positions_url
        - gtfs_rt_service_alerts_url
        - gtfs_rt_trip_updates_url
```

## Container Image

To build a container image of the service:

```bash
dirty=$(git diff-index HEAD)
test -z "$dirty" || git stash push
docker build -t us.gcr.io/cal-itp-data-infra/gtfs-rt-archive:$(git rev-parse HEAD) services/gtfs-rt-archive
test -z "$dirty" || git stash pop
```

### push to gcr

```bash
# ensure proper account selected
# use gcloud auth login as needed
gcloud auth list

# setup $HOME/.docker/config.json
gcloud auth configure-docker

# push image
docker push us.gcr.io/cal-itp-data-infra/gtfs-rt-archive:$(git rev-parse HEAD)
```
## Updating and restarting preprod and prod services

If any code changes occurred, maybe do the docker push thing above?

The gtfs-rt-archive service gets restarted during the `move DAGs to GCS folder` GitHub action defined in the [push_to_gcloud.yml](https://github.com/cal-itp/data-infra/blob/main/.github/workflows/push_to_gcloud.yml) file. During the restart any updated information from the agencies.yml and headers.yml will be updated in the preprod or production environment. In affected pull requests, the preprod service gets restarted on each commit. Once merged to main, the production service gets restarted.

If adding a new environment variable to the script, additional editing of the kubernetes config will need to be done and some editing of the config in the Kubernetes Engine console may need to occur prior to restarting a service.
