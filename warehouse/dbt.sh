#!/bin/bash
docker build -t local-dbt -f Dockerfile.local .
docker run --entrypoint dbt -v $(pwd):/app local-dbt "$@"
