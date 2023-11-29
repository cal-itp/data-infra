# Airflow

The following folder contains the project level directory for all our [Apache Airflow](https://airflow.apache.org/) [DAGs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html). Airflow is an orchestration tool that we use to manage our raw data ingest. Airflow DAG tasks are scheduled at regular intervals to perform data processing steps, like unzipping raw GTFS zipfiles and writing the contents out to Google Cloud Storage.

Our DAGs, plugins, and changes to [the Airflow image we use for local testing](./Dockerfile) are deployed automatically to Google Cloud Composer when a PR is merged into the `main` branch; see the section on deployment below for more information. Images used by some of our Airflow DAGs (i.e. those which are configured with PodOperators) are deployed separately, often also automatically upon merged changes to the relevant Dockerfiles in the repository. System configuration for worker count, environment variables, and overrides of Airflow configs are deployed via the [Composer web console](https://console.cloud.google.com/composer/environments?project=cal-itp-data-infra), not via an automated process, but additional dependencies that we add to the standard Composer-managed Airflow install (listed in [requirements.txt](./requirements.txt)) _are_ deployed automatically upon merged changes.

## Structure

The DAGs for this project are stored and version controlled in the `dags` folder. Each DAG has its own `README` with further information about its specific purpose and considerations. We use [gusty](https://github.com/pipeline-tools/gusty) to simplify DAG management.

Each DAG folder contains a [`METADATA.yml` file](https://github.com/pipeline-tools/gusty#metadata) that contains overall DAG settings, including the DAG's schedule (if any).

The logs are stored locally in the `logs` folder. You should be unable to add files here but the folder utilizes [a .gitkeep file](https://stackoverflow.com/a/7229996) so that it is consistently avaliable when testing and debugging.

Finally, Airflow plugins can be found in `plugins`; this includes general utility functions as well as custom [operator](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/operators.html) definitions.

## Testing Changes

This project is developed using Docker and docker-compose. Before getting started, please make sure you have [installed Docker on your system](https://docs.docker.com/get-docker/). Docker will need to be running at the time you run any `docker-compose` commands from the console.

To test any changes you've made to DAGs, operators, etc., you'll need to make sure that the UID and GID of the container match. To do so, run

```console
cd airflow (if you are not already in the airflow directory)
mkdir ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env
```

Second, ensure you have a default authentication file by [installing Google SDK](https://cloud.google.com/sdk/docs/install) and running

```console
unset GOOGLE_APPLICATION_CREDENTIALS
gcloud init

# When selecting the project, pick `cal-itp-data-infra`

# may also need to run...
# gcloud auth application-default login
```

Next, run the initial database migration (which also creates a default local Airflow user named `airflow`).

```shell
docker-compose run airflow db init
```

Next, start all services including the Airflow web server.

```console
docker-compose up
```

After a loading period, the Airflow web UI will become available. To access the web UI, visit `http://localhost:8080`.
The default login and password for our Airflow development image are both "airflow".

You may execute DAGs via the web UI, or specify individual tasks via the CLI:

```console
docker-compose run airflow tasks test download_gtfs_schedule_v2 download_schedule_feeds 2022-04-01T00:00:00
```

Additional reading about this setup can be found on the [Airflow Docs](https://airflow.apache.org/docs/apache-airflow/stable/start/docker.html)

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
docker-compose run airflow tasks test unzip_and_validate_gtfs_schedule_hourly validate_gtfs_schedule 2023-06-07T16:00:00
```

### Common Issues

- `docker-compose up` exits with code 137 - Check that Docker has enough RAM (e.g. 8Gbs). See [this post](https://stackoverflow.com/questions/44533319/how-to-assign-more-memory-to-docker-container) on how to increase its resources.

## Deploying Changes to Production

We have a [GitHub Action](../.github/workflows/deploy-airflow.yml) that runs when PRs touching this directory merge to the `main` branch. The GitHub Action updates the requirements sourced from [requirements.txt](./requirements.txt) and syncs the [DAGs](./dags) and [plugins](./plugins) directories to the bucket that Composer watches for code/data to parse. As of 2023-07-18, this bucket is `us-west2-calitp-airflow2-pr-171e4e47-bucket`.

Our production Composer instance is called [calitp-airflow2-prod](https://console.cloud.google.com/composer/environments/detail/us-west2/calitp-airflow2-prod/monitoring); its configuration (including worker count, Airflow config overrides, and environment variables) is manually managed through the web console. When scoping upcoming upgrades to the specific Composer-managed Airflow version we use in production, it can be helpful to grab the corresponding list of requirements from the [Cloud Composer version list](https://cloud.google.com/composer/docs/concepts/versioning/composer-versions), copy it into `requirements-composer-[COMPOSER_VERSION_NUMBER]-airflow-[AIRFLOW_VERSION_NUMBER].txt`, change [Dockerfile.composer](./Dockerfile.composer) to reference that file (deleting the previous equivalent) and modify the `FROM` statement at the top to grab the correct Airflow and Python versions for that Composer version, and build the image locally.

It is desirable to keep our local testing image closely aligned with the production image, so the `FROM` statement in [Dockerfile](./Dockerfile) should always reflect the same Airflow version and Python version that are being run in the Composer-managed production environment.
