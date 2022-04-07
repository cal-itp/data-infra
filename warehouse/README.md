This dbt project is intended to be the source of truth for the data-infra-cal-itp BigQuery warehouse.

### Executing the project
1. Configure your profiles.yml as described in the [dbt docs](https://docs.getdbt.com/dbt-cli/configure-your-profile).
2. Install poetry as described in the [poetry docs](https://python-poetry.org/docs/#osx--linux--bashonwindows-install-instructions).
3. Execute `poetry install` (just the first time) and `poetry run dbt run` to run the dbt project.

TODO: project standards and organization
