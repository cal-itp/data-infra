# Airflow

The following folder contains the project level directory for all our apache airflow ETLs, which are deployed automatically to Google Cloud Composer from the `main` branch.

## Structure

The DAGs for this project are stored and version controlled in the `dags` folder.

The logs are stored locally in the `logs` folder. You should be unable to add files here but it is gitkeep'ed so that it is avaliable when testing and debugging.

Finally, Airflow plugins can be found in `plugins`.

## Developing Locally

This project is developed using docker and docker-compose. Before getting started, please make sure you have installed both on your system.

First, if you're on linux, you'll need to make sure that the UID and GID of the container match, to do so, run

```console
cd airflow (if you are not already in the airflow directory)
mkdir ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env
```

Second, ensure you have a default authentication file, by [installing google sdk](https://cloud.google.com/sdk/docs/install) and running

```console
unset GOOGLE_APPLICATION_CREDENTIALS
gcloud init

# When selecting the project, pick `cal-itp-data-infra`

# may also need to run...
# gcloud auth application-default login
```

Next, run the initial database migration which also creates a default user named `airflow.
```shell
docker-compose run airflow db init
```

Next, start all services including the Airflow web server.
```console
docker-compose up
```

To access the web UI, visit `http://localhost:8080`.
The default login and password for airflow's image are both "airflow".

You may execute DAGs via the web UI, or just specific individual tasks via the CLI.

```console
docker-compose run airflow tasks test download_gtfs_schedule_v2 download_schedule_feeds 2022-04-01T00:00:00
```

Additional reading about this setup can be found on the [Airflow Docs](https://airflow.apache.org/docs/apache-airflow/stable/start/docker.html)

### Common Issues

* `docker-compose up` exits with code 137 - Check that your docker has enough RAM (e.g. 8Gbs). See [this post](https://stackoverflow.com/questions/44533319/how-to-assign-more-memory-to-docker-container) on how to increase its resources.

## Deploying to production

We have a [GitHub Action](../.github/workflows/deploy_airflow_dags.yml) defined that updates requirements and syncs the [dags](./airflow/dags) and [plugins](./airflow/plugins) directories to the bucket which Composer watches for code/data to parse. As of 2023-04-11, this bucket is `us-west2-calitp-airflow2-pr-171e4e47-bucket`. Our production Composer instance is called [calitp-airflow2-prod](https://console.cloud.google.com/composer/environments/detail/us-west2/calitp-airflow2-prod/monitoring); its configuration (including worker count, Airflow config overrides, and environment variables) is manually managed through the web console.
