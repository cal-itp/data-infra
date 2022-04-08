#!/bin/bash
set -e

dbt-metabase models \
    --dbt_path . \
    --dbt_database cal-itp-data-infra \
    --dbt_schema views \
    --metabase_host dashboards.calitp.org \
    --metabase_user $METABASE_USER \
    --metabase_password $METABASE_PASSWORD \
    --metabase_database "(Internal) Staging Warehouse Views"
