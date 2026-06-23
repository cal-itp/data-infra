#!/usr/bin/env bash
set -euo pipefail

# uv sync
uv sync --locked --all-groups --directory warehouse
uv sync --locked --all-groups --directory airflow

echo "✅ Dev‑container setup complete."
