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
import json
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook

class BigQueryToPartitionedGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "ts",
        "dataset_name",
        "table_name",
        "destination_bucket",
        "destination_path",
        "columns",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dataset_name: str,
        table_name: str,
        ts: str,
        destination_bucket: str,
        destination_path: str,
        columns: list[str] = [
            "key",
            "service_date",
            "base64_url",
			"trip_id",
            "trip_instance_key",
            "position_longitude",
            "position_latitude",
            "location_timestamp"
        ],
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self._big_query_hook = None
        self.ts: str = ts
        self.dataset_name = dataset_name
        self.table_name = table_name
        self.destination_bucket = destination_bucket
        self.destination_path = destination_path
        self.columns = columns
        self.gcp_conn_id = gcp_conn_id
        # does start_date and end_date get defined here to be used in sql?

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def location(self) -> str:
        return os.getenv("CALITP_BQ_LOCATION")

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(
            gcp_conn_id=self.gcp_conn_id, location=self.location(), use_legacy_sql=False
        )

    def rows(self, start_service_date, end_service_date) -> pd.DataFrame:
		"""
		Select from fct_vehicle_locations (partiitoned on dt). A parent of it uses
		int_gtfs_rt__vehicle_positions_trip_day_map_grouping, which already
		converts dt to service_date, so querying by service_date here should be reasonable.
		"""
		
		selected_columns = ", ".join(self.columns) if self.columns else "*"
		
		return self.bigquery_hook().get_df(
			sql=f"""
            	SELECT {selected_columns}
            	FROM `{self.dataset_name}.{self.table_name}`
            	WHERE service_date >= DATE('{start_service_date}') AND service_date <= DATE('{end_service_date}')
        	""",
			df_type="pandas"
		)
    
	def rows_grouped_by_trip(self, start_service_date, end_service_date) -> pd.DataFrame:
		"""
		Other trip-level rows to save as arrays
		"""
		
        return self.bigquery_hook().get_df(
			sql=f"""
	            SELECT 
					service_date,
					gtfs_dataset_key,
					base64_url,
					gtfs_dataset_name,
					schedule_gtfs_dataset_key,
					schedule_base64_url,
					schedule_name,
					schedule_feed_key,
					trip_id,
					trip_instance_key,
					
					ARRAY_AGG(
					    -- ignore nulls so it doesn't error out if there's a null point
						location IGNORE NULLS
						ORDER BY location_timestamp
					) AS pt_array,
					ARRAY_AGG(
						location_timestamp 
						ORDER BY location_timestamp
					) AS location_timestamp_utc,
					ARRAY_AGG(
						DATETIME(location_timestamp, "America/Los_Angeles") IGNORE NULLS 
						ORDER BY location_timestamp
					) AS location_timestamp_pacific,
					ARRAY_AGG(
	            		EXTRACT(HOUR FROM DATETIME(location_timestamp, "America/Los_Angeles")) * 3600
	              		+ EXTRACT(MINUTE FROM DATETIME(location_timestamp, "America/Los_Angeles")) * 60
	              		+ EXTRACT(SECOND FROM DATETIME(location_timestamp, "America/Los_Angeles"))
	             		IGNORE NULLS
	           		 ORDER BY location_timestamp
	        		) AS pacific_seconds,
					COUNT(*) AS n_vp,
	            FROM `{self.dataset_name}.{self.table_name}`
	            WHERE service_date >= DATE('{start_service_date}') AND service_date <= DATE('{end_service_date}')
				GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	        """,
			df_type="pandas"
		)
		
	def enrich_rows_with_movingpandas(df: pd.DataFrame) -> pd.DataFrame:
		"""
		Use movingpandas TrajectoryCollection to add all the deltas (distance, time, acceleration, direction)
		we can add.
		TrajectoryCollection keeps these new columns, but drops a lot in the process.
		Group by trip and save all the columns as arrays.
		Get the other trip-related columns we want in another query.
		"""
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
		# when TrajectoryCollection is created, position_longitude/latitude and location_timestamp will drop off
	    result_df = pd.concat([traj.df.drop(columns="geometry") for traj in tc], axis=0, ignore_index=True)

	    round_me = [
	        "distance_meters", "speed_mph", "acceleration_mph_per_sec",
	        "angular_difference", "direction",
	    ]
	    result_df[round_me] = result_df[round_me].round(3)
	    result_df = result_df.assign(
	        timedelta_seconds=result.timedelta.dt.total_seconds(),  # without this, timedelta is getting saved out as microseconds
	    )

		array_cols = [
			"distance_meters", "timedelta_seconds", # don't include timedelta (microseconds)
			"speed_mph", "acceleration_mph_per_sec",
			"angular_difference", "direction",
		]

		# movingpandas returns sorted df, so we can group and create trip-grain arrays here.
		# the length of these arrays = n_vp, because movingpandas inserts a NaN as first item in array 
		# (1st vp has no prior pt to calculate delta against)
		result_wide_df = (
			result
			.groupby(["service_date", "base64_url", "trip_instance_key"], dropna=False)
			.agg({
				c: lambda x: list(x) for c in array_cols
			})
			.reset_index()
		)

		return result_wide_df

	def process_vehicle_trajectory(self) -> pd.DataFrame:
		vp_trip_df = self.rows_grouped_by_trip()
		movingpandas_df = self.rows().enrich_rows_with_movingpandas()

		vp_trajectory_by_trip = pd.merge(
			vp_trip_df,
			movingpandas_df,
			on = ["service_date", "base64_url", "trip_instance_key"],
			how = "inner",
		)
		
		return vp_trajectory_by_trip
		
	def metadata(self) -> dict:
        return {
            "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                {
                    "filename": "configs.jsonl.gz",
                    "ts": self.ts,
                }
            )
        }

    def execute(self, context: Context) -> str:
        client = self.bigquery_hook().get_client()
		data = self.process_vehicle_trajectory()
      
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data=data,
            mime_type="application/jsonl",
            gzip=True,
            metadata=self.metadata(),
        )
        return {"destination_path": self.destination_path}
