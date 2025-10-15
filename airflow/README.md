# Airflow

The following folder contains the project level directory for all our [Apache Airflow](https://airflow.apache.org/) [DAGs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html). Airflow is an orchestration tool that we use to manage our raw data ingest. Airflow DAG tasks are scheduled at regular intervals to perform data processing steps, like unzipping raw GTFS zipfiles and writing the contents out to Google Cloud Storage.


## Local Development

This project uses [composer-local-dev](https://github.com/GoogleCloudPlatform/composer-local-dev) to run DAGs locally.

In order to run most DAGs, you will need to follow a few setup steps.

Login with `gcloud`:

```bash
$ gcloud auth application-default login --login-config=../iac/login.json
```

Install poetry dependencies inside the warehouse and compile dbt:

```bash
$ cd ../warehouse
$ poetry install
$ poetry run dbt deps
$ poetry run dbt compile --target staging
```

Install poetry dependencies for airflow:

```bash
$ cd ../airflow
$ poetry install
```

Setup composer environment:

```bash
$ make setup
```

Synchronize the environment files:

```bash
$ make sync
```

Start the reactor (this also runs `make setup` and `make sync`):

```bash
$ make start
```

After a loading period, the Airflow UI will become available at [`http://localhost:8080`](http://localhost:8080).

When setting up a new environment, you may want to create Airflow pools:

```bash
$ make pools
```

If you're running any DAGs that require secrets or service-specific connection values, you may need to set those in the `Connections` tab in Airflow.

Additional reading about general Airflow setup via Docker can be found on the [Airflow Docs](https://airflow.apache.org/docs/apache-airflow/stable/start/docker.html).

### PodOperators

Airflow PodOperator tasks execute a specific Docker image; these images are pushed to [GitHub Container Registry](https://ghcr.io/) and production uses `:latest` tags while local uses `:development`. If you want to test these tasks locally, you must build and push development versions of the images used by the tasks, which requires [proper access](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry). The Dockerfiles and code that make up the images live in the [/jobs](../jobs) directory. For example:

```bash
# running from jobs/gtfs-schedule-validator/
docker build -t ghcr.io/cal-itp/data-infra/gtfs-schedule-validator:development .
docker push ghcr.io/cal-itp/data-infra/gtfs-schedule-validator:development
```

### Common Issues

- If you want to clear out old local Airflow data, you'll need to delete the DAG using `poetry run composer-dev run-airflow-cmd calitp-development-composer dags delete <DAG_ID>` where, for example, the `<DAG_ID>` is `create_external_tables`

- If you want to reset the Airflow database entirely, you'll need to delete the direcotry where the Postges container stores its data: `make clean-postgres`

- On macOS, if `composer-dev` complains it cannot connect to Docker, open Docker Desktop, `Settings > Advanced` and ensure that `Allow the default Docker socket to be used` is checked.

- Airflow exits with code 137 - Check that Docker has enough RAM (e.g. 8Gbs). See [this post](https://stackoverflow.com/questions/44533319/how-to-assign-more-memory-to-docker-container) on how to increase Docker resources.

- When testing a new or updated `requirements.txt`, you might not see packages update. You may need to run `make restart` to clear out old data.

- If a task does not start when expected, its designated [pool](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/pools.html) may not have been created locally. Pools can be created and managed in Airflow on a page accessed via the Admin -> Pools menu option. A DAG's designated pool can typically be found on its DAG Details page, and is generally defined in the `default_args` section of the DAG's `METADATA.yml` file.

- If a task is producing errors but not producing complete logs for troubleshooting, or if it's reporting a memory issue, you may need to increase the RAM given by default to the Docker virtual machine that Airflow runs on. In Docker Desktop this setting can be accessed via the Preferences -> Advanced menu, and requires a restart of the VM to take effect.


## Deployment

Airflow deployment is managed automatically by Terraform, automated by Github Actions. If you manually deploy Airflow, Terraform will delete the deployment the next time it applies a plan.

- The `dags/`, `plugins/`, and `../warehouse` directories are deployed automatically when a PR is merged into the `main` branch via terraform from the `iac/cal-itp-data-infra/airflow` directory for production and the `iac/cal-itp-data-infra-staging/airflow` directory for staging.
- System configuration for worker count, environment variables, `requirements.txt`, and overrides of Airflow configs are deployed via terraform from the `iac/cal-itp-data-infra/composer` directory for production and the `iac/cal-itp-data-infra-staging/composer` directory for staging.
- Upgrades to Airflow/Composer versions are perfomed by editing the `config.software_config.image_version` value in `environment.tf`.
- The Docker containers used by `PodOperator` DAGs are built when a PR is merged into the `main` branch. More information can be found in the respective image READMEs.
- Environment variables for each environment are set via `.<environment>.env` files, (e.g., staging variables are in `.staging.env`).


## Structure

The DAGs for this project are stored and version controlled in the `dags` folder. Each DAG has its own `README.md` with further information about its specific purpose and considerations.

Schedules are generally specified in cron format, and the Airflow scheduler uses the internal concept of a [data interval](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dag-run.html#data-interval) to determine whether to kick off a DAG when scheduled. Some additional reading on the interaction between crontab values and Airflow's DAG start logic can be found in [this blog post](https://whigy.medium.com/why-my-scheduled-dag-does-not-run-9e2811b5030b).

When developing locally, logs for DAG runs are stored in the `logs/` directory. You should be unable to add files here, but the folder utilizes [a .gitkeep file](https://stackoverflow.com/a/7229996) so that it is consistently avaliable when testing and debugging.

Finally, Airflow plugins can be found in the `plugins/` directory; this includes general utility functions as well as custom [operator](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/operators.html) definitions.

### [gusty](https://github.com/pipeline-tools/gusty)

If a DAG contains a `METADATA.yml` file, it uses gusty. Each DAG folder contains a [`METADATA.yml` file](https://github.com/pipeline-tools/gusty#metadata) that contains overall DAG settings, including the DAG's schedule (if any).

### [cosmos](https://github.com/astronomer/astronomer-cosmos)

dbt dags are run using Cosmos, which turns a set of dbt models into a graph.


## Running automated tests

Each DAG for this project should have a corresponding test in the `tests/dags` folder. Tests are run from the command line and require a local installation of airflow to function.

1. `cp .env.example .env`
2. Fill in requested credentials
3. `poetry install`
4. `poetry run pytest`


You can specify which tests you want to run by adding them after the `pytest` command.

To run all tests files from a specific path, add the path like this:

```bash
$ poetry run pytest tests/scripts
```

To run a specific test file, add the file like this:

```bash
$ poetry run pytest tests/scripts/test_gtfs_rt_parser.py
```

To run a specific test within a test file, you can add like this:

```bash
$ poetry run pytest tests/scripts/test_gtfs_rt_parser.py::TestGtfsRtParser::test_no_vehicle_positions_for_date
```


## Testing Changes on Staging

If you want to test changes on Airflow Staging without changing Production, you have two options described bellow.

Changes applied only to Staging can be overwride at any time, whenever a PR is merged or if someone else also applies to Staging.

So, before applying your changes, inform on `#data-infra` channel in the Cal-ITP Slack.


### Apply automaticaly via staging branch

  1. Create a new branch starting with `staging/` (for example: `staging/my-changes`).
  2. Make your changes and push to Github.
  3. Visualize the progress of the workflow applying the changes through Terraform on [Github Actions](https://github.com/cal-itp/data-infra/actions).
  4. Once it is completed, you can test your changes on [Airflow Staging](https://console.cloud.google/composer/environments/detail/us-west2/calitp-staging-composer).


### Manually apply

  1. Make your changes
  2. Login with google cloud `gcloud auth application-default login --login-config=../iac/login.json`
  3. Go to Terraform-Staging-Airflow path: `iac/cal-itp-data-infra-staging/airflow/us/`
  4. Run `terraform plan` to view the changes
  5. Run `terraform apply` to apply your changes
  6. Once it completes, you can test your changes on [Airflow Staging](https://console.cloud.google/composer/environments/detail/us-west2/calitp-staging-composer).


## Deploying Changes to Production

We have a [GitHub Action](../.github/workflows/deploy-airflow.yml) that runs when PRs touching this directory merge to the `main` branch. The GitHub Action updates the requirements sourced from [requirements.txt](./requirements.txt) and syncs the [DAGs](./dags) and [plugins](./plugins) directories to the bucket that Composer watches for code/data to parse. As of 2025-07-16, this bucket is `calitp-composer` on production and `calitp-staging-composer` on staging.


## Secrets

Airflow operators have dependencies on the following secrets, which are required to be set:

- `airflow-connections-airtable_default` is a password formatted according to Airflow connection conventions (e.g. `airflow://login:abc123@airflow`), see <https://cloud.google.com/composer/docs/composer-2/configure-secret-manager>
- `airflow-connections-http_kuba`
- `airflow-connections-http_transitland`
- `airflow-connections-http_mobility_database`
- `airflow-connections-http_ntd`
- `airflow-connections-http_blackcat`
- `CALITP__ELAVON_SFTP_PASSWORD`

The following are provided by Littlepay to DDS:

- `LITTLEPAY_AWS_IAM_ANAHEIM_TRANSPORTATION_NETWORK_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_ATN_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_CAL_ITP_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_CALITP_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_CCJPA_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_CCJPA_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_HUMBOLDT_TRANSIT_AUTHORITY_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_HUMBOLDT_TRANSIT_AUTHORITY_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_LAKE_TRANSIT_AUTHORITY_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_LAKE_TRANSIT_AUTHORITY_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_MENDOCINO_TRANSIT_AUTHORITY_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_MENDOCINO_TRANSIT_AUTHORITY_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_MST_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_MST_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_NEVADA_COUNTY_CONNECTS_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_NEVADA_COUNTY_CONNECTS_ACCESS_KEY_V3`
- `LITTLEPAY_AWS_IAM_REDWOOD_COAST_TRANSIT_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_REDWOOD_COAST_TRANSIT_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_SACRT_ACCESS_KEY_FEED_V3`
- `LITTLEPAY_AWS_IAM_SBMTD_ACCESS_KEY`
- `LITTLEPAY_AWS_IAM_SBMTD_ACCESS_KEY_FEED_V3`
