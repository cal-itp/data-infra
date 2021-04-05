# Airflow / ETL

The following folder contains the project level directory for all our apache airflow ETLs, which are deployed automatically to Google Cloud Composer from the `main` branch.

## Structure

The DAGs for this project are stored and version controlled in the `dags` folder.

The logs are stored locally in the `logs` folder. You should be unable to add files here but it is gitkeep'ed so that it is avaliable when testing and debugging.

Finally, Airflow plugins can be found in `plugins`.

## Developing Locally

This project is developed using docker and docker-compose. Before getting started, please make sure you have installed both on your system.

First, if you're on linux, you'll need to make sure that the UID and GID of the container match, to do so, run

```console
mkdir ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env
```

Second, ensure you have a default authentication file, by running

```console
unset GOOGLE_APPLICATION_CREDENTIALS
gcloud init
```

Finally, run the initial database migration and create an `airflow / airflow` user to debug with:

```console
docker-compose run airflow db init
```

Start all services with:

```console
docker-compose up
```

To access the web UI, visit `http://localhost:8080`.

To run a DAG, you can either test it via the web UI or run a one-off with:

```console
docker-compose run airflow dags trigger <dag_id>
```

Additional reading about this setup can be found on the [Airflow Docs](https://airflow.apache.org/docs/apache-airflow/stable/start/docker.html)

## Deploying to production

All gcs assets are under the project `cal-itp-data-infra`. All assets should be using the `us-west-2` region.

Currently, the project is automatically deploy to a cloud composer managed airflow service named `calitp-airflow-prod`. Cloud Composer excepts a GCS bucket full of DAGs, so we use Github Actions to automatically sync the `dags` folder to the production bucket and update the python dependencies in `requirements.txt`. There is a service user setup using Github Actions Secrets to handle auth.

To view the prod webserver or logs, login to the cloud composer console.

Note that the following variables were set manually in cloud composer:

* `AIRFLOW_VAR_EXTRACT_BUCKET` - gcs bucket for data (e.g. `gs://gtfs-data`)
* `SENDGRID_API_KEY`
* `SENDGRID_MAIL_FROM`
* `POD_CLUSTER_NAME` - name of the kubernetes cluster
* `POD_LOCATION` - location of cluster (e.g. us-west-2a)
