---
jupytext:
  cell_metadata_filter: -all
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.10.3
kernelspec:
  display_name: Python 3 (ipykernel)
  language: python
  name: python3
---

## GTFS CKAN Uploader

See readme in [services/gtfs-ckan-uploader](https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archive/README.md).

## gtfs-rt-archive

### Quickstart

See dependencies section below for details on prerequisites

```bash
export CALITP_LOG_LEVEL=debug
export CALITP_DATA_DEST=gs://gtfs-data/rt
export CALITP_DATA_DEST_SECRET=$HOME/Downloads/cal-itp-data-infra-661571285e30.json
export CALITP_AGENCIES_YML=$HOME/Downloads/data_agencies.yml
python services/gtfs-rt-archive/gtfs-rt-archive.py
```

### Dependencies

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
