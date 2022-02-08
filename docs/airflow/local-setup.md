# Local Airflow

## Running Airflow Locally
You can run an instance of airflow locally using `docker-compose`. To do so, in the `data-infra` repo, within the `airflow` directory, run: `docker-compose up`.

## Pulling Pod Logs for PodOperator DAG Tasks
To pull pod logs for PodOperator DAG tasks during a local airflow run,
1. Navigate to `GCP` > `Operations` > `Logging` > `Logs Explorer` > _the query field_
2. Run the following query, substituting the name of the pod with the pod whose logs you would like to retrieve:

`resource.labels.pod_name="pod.name"`
ex.

`resource.labels.pod_name="gtfs-rt-validation.85d1bfec8223489d886be905ff234a03"`

If you're unsure of the name of a pod, in your local Airflow UI:
1. Navigate to the logs section for an individual PodOperator DAG task
2. Search for log messages similar to this, which will provide the name of the pod:

`Pod not yet started: gtfs-rt-validation.87a693a129d64ccdb3d9d21bf29c2f46`
