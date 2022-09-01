#!/bin/bash
docker build -t local-dbt -f Dockerfile.local .
docker run --entrypoint dbt -e GOOGLE_APPLICATION_CREDENTIALS=/gcloud_config/application_default_credentials.json -v ~/.dbt:/local_dbt -v ~/.config/gcloud:/gcloud_config -v $(pwd):/app local-dbt "$@" --profiles-dir /local_dbt
