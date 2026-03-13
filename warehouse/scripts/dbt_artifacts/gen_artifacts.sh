#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

uv run datamodel-codegen --url https://schemas.getdbt.com/dbt/catalog/v1.json --output ./catalog.py --field-constraints --use-double-quotes --allow-extra-fields
uv run datamodel-codegen --url https://schemas.getdbt.com/dbt/manifest/v9.json --output ./manifest.py --field-constraints --use-double-quotes --allow-extra-fields
uv run datamodel-codegen --url https://schemas.getdbt.com/dbt/run-results/v4.json --output ./run_results.py --field-constraints --use-double-quotes --allow-extra-fields
uv run datamodel-codegen --url https://schemas.getdbt.com/dbt/sources/v3.json --output ./sources.py --field-constraints --use-double-quotes --allow-extra-fields
