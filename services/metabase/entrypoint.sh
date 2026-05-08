#!/bin/bash
set -euo pipefail

if [[ -z "${CLOUD_SQL_INSTANCE_CONNECTION_NAME:-}" ]]; then
  detected=$(ls /cloudsql 2>/dev/null | head -1 || true)
  if [[ -n "$detected" ]]; then
    CLOUD_SQL_INSTANCE_CONNECTION_NAME="$detected"
  else
    echo "ERROR: CLOUD_SQL_INSTANCE_CONNECTION_NAME must be set, or a single Cloud SQL instance must be mounted at /cloudsql/" >&2
    exit 1
  fi
fi

ln -sf "/cloudsql/${CLOUD_SQL_INSTANCE_CONNECTION_NAME}/.s.PGSQL.5432" /app/pg.sock

nohup socat -d -d TCP4-LISTEN:5432,fork UNIX-CONNECT:/app/pg.sock &

exec /app/run_metabase.sh
