# Cal-ITP's dbt project

This dbt project is intended to be the source of truth for the cal-itp-data-infra BigQuery warehouse.

##  Setting up the project on your local machine

> Note: if you get `Operation not permitted` when attempting to use the terminal,
> you may need to [fix your terminal permissions](https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/)

### Install Homebrew (if you haven't)
1. Follow the installation instructions at https://brew.sh/
2. Then, `brew install gdal` to install a geospatial library needed later

### Install the Google SDK (if you haven't)
0. Implied: make sure that you have GCP permissions (i.e. that someone has added you to the GCP project)
1. Follow the installation instructions at https://cloud.google.com/sdk/docs/install
2. You must also [authorize](https://cloud.google.com/sdk/docs/authorizing) and [set the application default](https://cloud.google.com/sdk/gcloud/reference/auth/application-default)
3. If `bq ls` shows output, you are good to go.


### Install poetry and Python/dbt dependencies
1. Install poetry (used for package/dependency management). You can try as described in the [poetry docs](https://python-poetry.org/docs/#osx--linux--bashonwindows-install-instructions) -- this has not worked for some of us; we have had to run `python3 -m pip install poetry`. **Note: If you have to `pip install` poetry, then in all the commands below, you will need to prefix them with `python3 -m`. So the `poetry install` command becomes `python3 -m poetry install`.**
2. Navigate into the `data-infra/warehouse` directory and run the following commands:
3. `poetry install` to create a virtual environment and install requirements
   1. If this doesn’t work because of an error with Python version, you may need to install Python 3.9
   2. `brew install python@3.9`
   3. `brew link python@3.9`
   4. After restarting the terminal, confirm with `python3 --version` and retry `poetry install`
4. `poetry run dbt deps` to install the dbt dependencies defined in `packages.yml` (such as `dbt_utils`)

### Initialize your dbt profiles.yml
1. `poetry run dbt init` inside `warehouse/` will create a `.dbt/` directory in your home directory and a `.dbt/profiles.yml` file.
2. Fill out your `~/.dbt/profiles.yml` with the following content.
```yaml
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
3. See [the dbt docs on profiles.yml](https://docs.getdbt.com/dbt-cli/configure-your-profile) for more background on this file.

## Running the project locally

Once you have performed the setup above, you are good to go run
[dbt commands](https://docs.getdbt.com/reference/dbt-commands) locally!

Some especially helpful commands:
* `poetry run dbt compile` -- will compile all the models (generate SQL, with references resolved) but won't execute anything in the warehouse
* `poetry run dbt run` -- will run all the models -- this will execute SQL in the warehouse (specify [selections](https://docs.getdbt.com/reference/node-selection/syntax) to run only a subset of models, otherwise this will run *all* the tables)
* `poetry run dbt test` -- will test all the models (this executes SQL in the warehouse to check tables); for this to work, you first need to `dbt run` to generate all the tables to be tested
* `poetry run dbt docs generate` -- will generate the dbt documentation
* `poetry run dbt docs serve` -- will "serve" the dbt docs locally so you can access them via `http://localhost:8080`; note that you must `docs generate` before you can `docs serve`

TODO: project standards and organization
