# Airflow / ETL

The following folder contains the project level directory for all our apache airflow ETLs, which are deployed automatically to Google Cloud Composer from the `main` branch.

## Structure
The DAGs for this project are stored and version controlled in the `dags` folder.

The logs are stored locally in the `logs` folder. You should be unable to add files here but it is gitkeep'ed so that it is avaliable when testing and debugging.

Finally, Airflow plugins can be found in `plugins`.

## Developing Locally
This project is developed using docker and docker-compose. Before getting started, please make sure you have installed both on your system.

Additionally, if you're on linux, you'll need to make sure that the UID and GID of the container match, to do so, run

```
mkdir ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env
```

1. Run `docker-compose up airflow-init`. This runs the initial database migration and creates a `airflow / airflow` user to debug with.

1. You can now start all services. Run `docker-compose up` to start airflow. To access the webserver, visit `http://localhost:8080`.

To run a dag, you can either test it via the web UI or run a one-off dag by running `docker-compose up airflow dags trigger ...` from the command line.

Additional reading about this setup can be found on the [Airflow Docs](https://airflow.apache.org/docs/apache-airflow/stable/start/docker.html)

## Deploying to production
TK TK
