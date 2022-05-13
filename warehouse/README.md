# Cal-ITP's dbt project

This dbt project is intended to be the source of truth for the cal-itp-data-infra BigQuery warehouse.

##  Setting up the project on your local machine
0. [Authorize the gcloud CLI](https://cloud.google.com/sdk/docs/authorizing) so that you can access BigQuery (implied step -1: make sure that you have permissions for BigQuery)
1. Create a file `~/.dbt/profiles.yml` (i.e., in your home directory inside a `.dbt` subdirectory) that contains the following:
```
calitp_warehouse:
  target: dev
  outputs:
    dev:
      schema: <enter your first name or initials here, like "laurie" or "lam">
      fixed_retries: 1
      location: us-west2
      method: oauth
      priority: interactive
      project: cal-itp-data-infra-staging
      threads: 4
      timeout_seconds: 300
      type: bigquery
```

See [the dbt docs on profiles.yml](https://docs.getdbt.com/dbt-cli/configure-your-profile) for more background on this file.

2. Install poetry (used for package/dependency management). You can try as described in the [poetry docs](https://python-poetry.org/docs/#osx--linux--bashonwindows-install-instructions) -- this has not worked for some of us; we have had to run `python3 -m pip install poetry`. **Note: If you have to `pip install` poetry, then in all the commands below, you will need to prefix them with `python3 -m`. So the `poetry install` command becomes `python3 -m poetry install`.**
3. Navigate into the `data-infra/warehouse` directory and run the following commands:
    * To install general dependencies, including to install dbt itself: `poetry install`
    * To install dbt package dependencies: `poetry run dbt deps`

## Running the project locally

Once you have performed the setup above, you are good to go run [dbt commands](https://docs.getdbt.com/reference/dbt-commands) locally! As above, if you had to `pip install` poetry, you will need to prefix all commands with `python3 -m`.

Some especially helpful commands:
* `poetry run dbt compile` -- will compile all the models (generate SQL, with references resolved) but won't execute anything in the warehouse
* `poetry run dbt run` -- will run all the models -- this will execute SQL in the warehouse (specify [selections](https://docs.getdbt.com/reference/node-selection/syntax) to run only a subset of models, otherwise this will run *all* the tables)
* `poetry run dbt test` -- will test all the models (this executes SQL in the warehouse to check tables); for this to work, you first need to `dbt run` to generate all the tables to be tested
* `poetry run dbt docs generate` -- will generate the dbt documentation
* `poetry run dbt docs serve` -- will "serve" the dbt docs locally so you can access them via `http://localhost:8080`; note that you must `docs generate` before you can `docs serve`

TODO: project standards and organization
