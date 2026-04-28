import os
from datetime import datetime, timedelta

from dags import log_failure_to_slack
from operators.bigquery_vehicle_locations_to_gcs_vehicle_trajectories import (
    BigQueryVehicleLocationsToTrajectory,
)

from airflow.decorators import dag
from airflow.utils.trigger_rule import TriggerRule

# Set new bucket by Terrform 
# What's naming convention for buckets? Just 1 bucket for source + destination?
CALITP_BUCKET__GTFS_VEHICLE_LOCATIONS = os.environ["CALITP_BUCKET__GTFS_VEHICLE_LOCATIONS"]

@dag(
    # 3am UTC (8am PDT/7am PST) once a week
    schedule="0 3 * * *", #TODO switch to be once a week, this is daily
    start_date=datetime(2026, 5, 1),
    catchup=False,
    tags=["gtfs"],
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
)

def model_vp_trajectory():
  
    model_trajectory = BigQueryVehicleLocationsToTrajectory(
        task_id="model_trajectory",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dataset_name="mart_gtfs",
        table_name="fct_vehicle_locations",
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_VEHICLE_LOCATIONS"),
        # can this be partitioned on service_date?
        destination_path="vehicle_locations_trajectory/service_date={{ dt }}trajectories.jsonl.gz",
    )

    model_trajectory >> create_external_table 
    #TODO how to add the task to create the external table from the hive-partitioned bucket? how does the yaml get called? 
    # set trigger rule to success of model_trajectory


model_vp_trajectory_instance = model_trajectory()
