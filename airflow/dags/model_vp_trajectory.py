"""
Goal: use a DAG to take `mart_gtfs.fct_vehicle_locations` -> 
use movingpandas / Python to add trajectory -> 
results are configured external table, usable in downstream dbt model `mart_gtfs.fct_vehicle_locations_path`.

1. Be able to grab a week for `mart_gtfs.fct_vehicle_locations` for each DAG run,
save it into a hive-partitioned GCS bucket. 
Laurie: we have to have Airflow job to define partitions in explicit way.
  - [ ] use 1 bucket (make sure naming convention is correct)
  - [ ] ask MoV to use Terraform to set up
  - [ ] add `fct_vehicle_locations` in chunks, 1 week at a time, filter on dt, only necessary columns, saved to hive-partitioned GCS.
        save as gzipped jsonl? 
        BUCKET/fct_vehicle_locations/dt=2026-01-01; 
        BUCKET/fct_vehicle_locations/dt=2026-01-02; is this how partitions look like? 

2. Add a Python script that models the vehicle location trajectory (use movingpandas).
Laurie: script would operate on each partition at a time, so every dt
- [ ] movingpandas chunk - read in json, save results as gzipped jsonl 
- [ ] I need to double check results are what's expected / use it downstream and make sure
- [ ] movingpandas results also come out in chunks, 1 week at a time, saved to hive-partitioned GCS. 
      vehicle_locations_trajectory (? clear enough name?)
        BUCKET/vehicle_locations_trajectory/dt=2026-01-01; 
        BUCKET/vehicle_locations_trajectory/dt=2026-01-02; is this how partitions look like? 

3. Configure the results in BUCKET/vehicle_locations_trajectory/dt=* to be external table
- [ ] use the create_external_table DAG
- [ ] set the partitions (dt), clusters, 
- [ ] test that I can see it, use the 2 sources together in `fct_vehicle_locations_path` 

Airflow operators to use as examples: 
- bigquery_to_download_config_operator (selects subset of columns) 
- tdq_bigquery_rows_operator (selects a BQ table and returns it) 
- DAG: create_external_table - no current examples, we've moved much away 
"""
# ---
# python_callable: model_vehicle_locations_trajectory
# provide_context: true
# dependencies:
#   - bigquery_vehicle_locations_to_gcs (what is the task above called?)
# trigger_rule: all_done
# ---
import movingpandas as mpd
import os
import pandas as pd

from calitp_data_infra.storage import (
    PartitionedGCSArtifact,
    get_fs,
)
# Set new bucket by Terrform 
# What's naming convention for buckets? Just 1 bucket for source + destination?
CALITP_BUCKET__GTFS_VEHICLE_LOCATIONS = os.environ["CALITP_BUCKET__GTFS_VEHICLE_LOCATIONS"]

class MovingPandasOutput(PartitionedGCSArtifact):
    bucket: ClassVar[str] = "CALITP_BUCKET__GTFS_VEHICLE_LOCATIONS"
    source_table: ClassVar[str] = "fct_vehicle_locations" #in the bucket, partitions are fct_vehicle_locations/dt=* based on the bigquery_to_partitionedgcs operator?
    destination_table: ClassVar[str] = "vehicle_locations_trajectory"
    partition_names: ClassVar[str] = "dt"
    cluster_fields: ClassVar[list[str]] = ["base64_url"]
    data: Optional[pd.DataFrame]

    # class might not be defined correctly. source_table is really a folder within bucket, then all the partitions within it 
    # but when DAG runs, it adds 7 dts, then we do movingpandas on those 7, (function like dbt incremental models)
    # save results into output folder that's cumulative
    # external table would be configured on the cumulative results
    
    # how to modify this to save it into a separate folder within the bucket?
    def save_to_gcs(self, fs):
        self.save_content(
            fs=fs,
            content=gzip.compress(
                self.data.to_json(
                    orient="records", lines=True, default_handler=str
                ).encode()
            ),
            exclude={"data"},
        )

    # Or should saving to gcs be using gcs_hook in BigQueryToPartitionedGCSOperator? How to use it?
    
    
def add_movingpandas_columns(filename: str):
    """
    How to read in all the partitioned files? 
    Trips have to be grouped together, so would dt/service_date might matter here?
    """ 
    df = pd.read_json(filename, compression='gzip') 

    tc = mpd.TrajectoryCollection(
            df, 
            traj_id_col = "trip_instance_key", 
            obj_id_col = "key", 
            x = "position_longitude", 
            y = "position_latitude", 
            t = "location_timestamp"
        )
    tc.add_distance(overwrite=True, name="distance_meters", units="m")
    tc.add_timedelta(overwrite=True)
    tc.add_speed(overwrite=True, name="speed_mph", units=("mi", "h"))
    tc.add_acceleration(
        overwrite=True, name="acceleration_mph_per_sec", units=("mi", "h", "s")
    )
    tc.add_angular_difference(overwrite=True)
    tc.add_direction(overwrite=True)

    # movingpandas TrajectoryCollection will group each trip_instance_key as a trajectory
    # to get the results as df (https://movingpandas.github.io/movingpandas-website/1-tutorials/4-exporting-trajectories.html)
    # use what's underlying that: https://github.com/movingpandas/movingpandas/blob/main/movingpandas/trajectory_collection.py
    result = pd.concat([traj.df.drop(columns="geometry") for traj in tc], axis=0, ignore_index=True)

    round_me = [
        "distance_meters",
        "speed_mph",
        "acceleration_mph_per_sec",
        "angular_difference",
        "direction",
    ]
    result[round_me] = result[round_me].round(3)
    result = result.assign(
        timedelta_seconds=result.timedelta.dt.total_seconds(),  # without this, timedelta is getting saved out as microseconds
    )

    # what should be returned? the path to destination? the df? where can it be saved out?
    return 

def model_vp_trajectory_with_movingpandas():
    fs = get_fs()

    file_list = fs.ls(f"{CALITP_BUCKET__GTFS_VEHICLE_LOCATIONS}/fct_vehicle_locations/", detail=False)

    for f in file_list:
        df = add_movingpandas_columns(f)    

        # what is the class to be set here? 

        df.save_to_gcs(fs=fs) or df.gcs_hook to upload back to BUCKET/vehicle_locations_trajectory
        

if __name__ == "__main__":
    model_vp_trajectory_with_movingpandas()
