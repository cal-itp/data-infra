# Local Airflow

## Running Airflow Locally
You can run an instance of airflow locally using `docker-compose`. To do so,
* In the `data-infra` repo, within the `airflow` directory, run:
`docker-compose up`.

## Pulling PodOperator Logs for a Local Airflow Run
To pull pod logs,
1. Navigate to GCP > Operations > Logging > Logs Explorer > _query field_
2. Run the following query, substituting the name of the terminated pod with the pod whose logs you would like to retrieve:
`resource.labels.pod_name="pod.name"`
ex.
`resource.labels.pod_name="gtfs-rt-validation.85d1bfec8223489d886be905ff234a03"`

If you're unsure of the name of a pod, in your local Airflow UI:
1. Navigate to the logs section for an individual PodOperator DAG task
2. Search for log messages similar to this, which will provide the name of the pod:
`Pod not yet started: gtfs-rt-validation.87a693a129d64ccdb3d9d21bf29c2f46`
