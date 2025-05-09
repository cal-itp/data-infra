from airflow.decorators import task, dag
from datetime import datetime
from hooks.kuba_hook import KubaHook

@dag(
    schedule=None,
    start_date=datetime(2022, 1, 1),
    catchup=False,
    dag_id="sync_kuba"
)
def sync_kuba():
    @task
    def fetch_locations():
        return KubaHook().run(endpoint="monitoring/deviceproperties/v1/ForLocations/all?location_type=1")

    @task
    def fetch_devices():
        return KubaHook().run(endpoint="monitoring/deviceproperties/v1/ForDevices/all?device_type=1")

    # locations = fetch_locations()
    return fetch_locations()

dag = sync_kuba()
