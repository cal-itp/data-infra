#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

poetry run datamodel-codegen --url https://schemas.getdbt.com/dbt/catalog/v1.json --output "$SCRIPT_DIR"/catalog.py
poetry run datamodel-codegen --url https://schemas.getdbt.com/dbt/manifest/v9.json --output "$SCRIPT_DIR"/manifest.py
poetry run datamodel-codegen --url https://schemas.getdbt.com/dbt/run-results/v4.json --output "$SCRIPT_DIR"/run_results.py
poetry run datamodel-codegen --url https://schemas.getdbt.com/dbt/sources/v3.json --output "$SCRIPT_DIR"/sources.py
