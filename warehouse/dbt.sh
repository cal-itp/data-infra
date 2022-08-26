#!/bin/bash
docker build -t local-dbt -f Dockerfile.local .
docker run --entrypoint dbt -v ~/.dbt:/local_dbt -v $(pwd):/app local-dbt "$@" --profiles-dir /local_dbt
