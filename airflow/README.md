# Airflow

The following folder contains the project level directory for all our [Apache Airflow](https://airflow.apache.org/) [DAGs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html). Airflow is an orchestration tool that we use to manage our raw data ingest. Airflow DAG tasks are scheduled at regular intervals to perform data processing steps, like unzipping raw GTFS zipfiles and writing the contents out to Google Cloud Storage.

- Our *DAGs, plugins, and changes to [the Airflow image we use for local testing](./Dockerfile)* are deployed automatically when a PR is merged into the `main` branch; see the section on deployment below for more information.
- *Images used by our Airflow DAGs* (i.e. those which are configured with PodOperators) are deployed separately, and their deployment information can be found in the respective image READMEs.
- *System configuration for worker count, environment variables, and overrides of Airflow configs* are deployed via the [Composer web console](https://console.cloud.google.com/composer/environments?project=cal-itp-data-infra), not via an automated process.
  - Additional dependencies that we add to the standard Composer-managed Airflow install (listed in [requirements.txt](./requirements.txt)) are treated differently, deployed automatically upon merged changes to this repository just like DAG and plugin changes.


## Structure

The DAGs for this project are stored and version controlled in the `dags` folder. Each DAG has its own `README` with further information about its specific purpose and considerations. We use [gusty](https://github.com/pipeline-tools/gusty) to simplify DAG management.

Each DAG folder contains a [`METADATA.yml` file](https://github.com/pipeline-tools/gusty#metadata) that contains overall DAG settings, including the DAG's schedule (if any). Schedules are generally specified in cron format, and the Airflow scheduler uses the internal concept of a [data interval](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dag-run.html#data-interval) to determine whether to kick off a DAG when scheduled. Some additional reading on the interaction between crontab values and Airflow's DAG start logic can be found in [this blog post](https://whigy.medium.com/why-my-scheduled-dag-does-not-run-9e2811b5030b).

When developing locally, logs for DAG runs are stored in the `logs` subfolder. You should be unable to add files here, but the folder utilizes [a .gitkeep file](https://stackoverflow.com/a/7229996) so that it is consistently avaliable when testing and debugging.

Finally, Airflow plugins can be found in the `plugins` subfolder; this includes general utility functions as well as custom [operator](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/operators.html) definitions.


## Running automated tests

Each DAG for this project should have a corresponding test in the `tests/dags` folder. Tests are run from the command line and require a local installation of airflow to function.

1. `cp .env.example .env`
2. Fill in Kuba API credentials
3. `poetry install`
4. `poetry run pytest`


## Testing changes

This project is developed using Docker and docker compose, and we test most changes via a local version of Airflow that is similarly configured to the production Composer-managed Airflow instance - its dependencies are based on the dependency list from the Composer-managed production Airflow instance, copied into a file named `requirements-composer-[x.y.z]-airflow-[a.b.c].txt`. Before getting started, please make sure you have [installed Docker on your system](https://docs.docker.com/get-docker/). Docker will need to be running at the time you run any `docker compose` commands from the console.

To test any changes you've made to DAGs, operators, etc., you'll need to follow a few setup steps:

Ensure you have a default authentication file by [installing Google SDK](https://cloud.google.com/sdk/docs/install) and running

```console
gcloud auth login --login-config=iac/login.json
gcloud config set project cal-itp-data-infra-staging

# When selecting the project, pick `cal-itp-data-infra`

# may also need to run...
gcloud auth application-default login --login-config=iac/login.json
```

Next, run the initial database migration (which also creates a default local Airflow user named `airflow`).

```shell
docker compose run airflow db init
```

Next, start all services including the Airflow web server.

```console
docker compose up
```

After a loading period, the Airflow web UI will become available. To access the web UI, visit `http://localhost:8080`.
The default login and password for our Airflow development image are both "airflow".

You may execute DAGs via the web UI, or specify individual tasks via the CLI:

```console
docker compose run airflow tasks test download_gtfs_schedule_v2 download_schedule_feeds 2022-04-01T00:00:00
```

If a DAG you intend to run locally relies on secrets stored in Google Secret Manager, the Google account you authenticated with will need IAM permissions of "Secret Manager Secret Accessor" or above to access those secrets. Some nonessential secrets are not set via Google Secret Manager, so if you monitor Airflow logs while the application is running, you may see occasional warnings (rather than errors) about missing variables like CALITP_SLACK_URL that can be ignored unless you're specifically testing features that rely on those variables.

If you locally run any tasks that dispatch requests to use Kubernetes compute resources (i.e. any tasks that use PodOperators), the Google account you authenticated with will need to have access to Google Kubernetes Engine, which is most commonly granted via the "Kubernetes Engine Developer" IAM permission.

Uncommon or new use cases, like implementing Python models, may also require additional IAM permissions related to the specific services a developer wishes to access from their local development environment.

Additional reading about general Airflow setup via Docker can be found on the [Airflow Docs](https://airflow.apache.org/docs/apache-airflow/stable/start/docker.html).


### PodOperators

Airflow PodOperator tasks execute a specific Docker image; these images are pushed to [GitHub Container Registry](https://ghcr.io/) and production uses `:latest` tags while local uses `:development`. If you want to test these tasks locally, you must build and push development versions of the images used by the tasks, which requires [proper access](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry). The Dockerfiles and code that make up the images live in the [/jobs](../jobs) directory. For example:

```bash
# running from jobs/gtfs-schedule-validator/
docker build -t ghcr.io/cal-itp/data-infra/gtfs-schedule-validator:development .
docker push ghcr.io/cal-itp/data-infra/gtfs-schedule-validator:development
```

Then, you could execute a task using this updated image.

```bash
# running from airflow/
docker compose run airflow tasks test unzip_and_validate_gtfs_schedule_hourly validate_gtfs_schedule 2023-06-07T16:00:00
```


### Common Issues

- `docker compose up` exits with code 137 - Check that Docker has enough RAM (e.g. 8Gbs). See [this post](https://stackoverflow.com/questions/44533319/how-to-assign-more-memory-to-docker-container) on how to increase its resources.

- When testing a new or updated `requirements.txt`, you might not see packages update. You may need to run `docker compose down --rmi all` to clear out older docker images and recreate with `docker build . --no-cache`.

- If a task does not start when expected, its designated [pool](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/pools.html) may not have been created locally. Pools can be created and managed in Airflow on a page accessed via the Admin -> Pools menu option. A DAG's designated pool can typically be found on its DAG Details page, and is generally defined in the `default_args` section of the DAG's `METADATA.yml` file.

- If a task is producing errors but not producing complete logs for troubleshooting, or if it's reporting a memory issue, you may need to increase the RAM given by default to the Docker virtual machine that Airflow runs on. In Docker Desktop this setting can be accessed via the Preferences -> Advanced menu, and requires a restart of the VM to take effect.


## Deploying Changes to Production

We have a [GitHub Action](../.github/workflows/deploy-airflow.yml) that runs when PRs touching this directory merge to the `main` branch. The GitHub Action updates the requirements sourced from [requirements.txt](./requirements.txt) and syncs the [DAGs](./dags) and [plugins](./plugins) directories to the bucket that Composer watches for code/data to parse. As of 2025-04-03, this bucket is `us-west2-calitp-airflow2-pr-f6bb9855-bucket`.


## Secrets

Airflow operators have dependencies on the following secrets, which are required to be set:

- `airflow-connections-airtable_default` is a password formatted according to Airflow connection conventions (e.g. `airflow://login:abc123@airflow`), see <https://cloud.google.com/composer/docs/composer-2/configure-secret-manager>
- `airflow-jobs_jobs-data` contains a Kubernetes secret blob, including `transitland-api-key`
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


### Upgrading Airflow Itself

Our production Composer instance is called [calitp-airflow2-prod-composer2-20250402](https://console.cloud.google.com/composer/environments/detail/us-west2/calitp-airflow2-prod-composer2-20250402/monitoring); its configuration (including worker count, Airflow config overrides, and environment variables) is manually managed through the web console. When scoping upcoming upgrades to the specific Composer-managed Airflow version we use in production, it can be helpful to grab the corresponding list of requirements from the [Cloud Composer version list](https://cloud.google.com/composer/docs/concepts/versioning/composer-versions), copy it into `requirements-composer-[COMPOSER_VERSION_NUMBER]-airflow-[AIRFLOW_VERSION_NUMBER].txt`, change [Dockerfile.composer](./Dockerfile.composer) to reference that file (deleting the previous equivalent) and modify the `FROM` statement at the top to grab the correct Airflow and Python versions for that Composer version, and build the image locally.

It is desirable to keep our local testing image closely aligned with the production image, so the `FROM` statement in our automatically deployed [Dockerfile](./Dockerfile) should always be updated after a production Airflow upgrade reflect the same Airflow version and Python version that are being run in the Composer-managed production environment.
