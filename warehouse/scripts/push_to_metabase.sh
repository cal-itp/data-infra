#!/bin/bash
set -e

dbt-metabase models \
    --dbt_manifest_path ./target/manifest.json \
    --dbt_database cal-itp-data-infra \
    --metabase_host dashboards.calitp.org \
    --metabase_user $METABASE_USER \
    --metabase_password $METABASE_PASSWORD \
    --metabase_database "(Internal) Staging Warehouse Views"
