"""
Goal: use a DAG to take `mart_gtfs.fct_vehicle_locations` -> 
use movingpandas / Python to add trajectory -> 
results are configured external table, would become `fct_vehicle_locations_path`

1. Be able to grab a week for `mart_gtfs.fct_vehicle_locations` for each DAG run,
save it into a hive-partitioned GCS bucket. 
Laurie: we have to have Airflow job to define partitions in explicit way.
  - [ ] use 1 bucket (make sure naming convention is correct)
  - [ ] ask MoV to use Terraform to set up
  - [x] 1st query: add `fct_vehicle_locations` in chunks, 1 week at a time, filter on dt (or can we do service_date)? 
  - [x] 2nd query: do a query on `fct_vehicle_locations` in chunks + group by daily trip - this is what's in fct_vehicle_locations_path already
  - [x] enrich with movingpandas 
  - [ ] saved to hive-partitioned GCS.
       save as gzipped jsonl? 
	   can this be partitioned on service_date?
        
2. Configure the results in BUCKET/vehicle_locations_trajectory/dt=* to be external table - becomes fct_vehicle_locations_path (but with more columns)
- [x] use the create_external_table DAG
- [ ] set the partitions (service_date), clusters
"""


import json
import os
from datetime import datetime, timedelta, timezone
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook

class BigQueryVehicleLocationsToTrajectory(BaseOperator):
    template_fields: Sequence[str] = (
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
        destination_bucket: str,
        destination_path: str = "vehicle_trajectory",
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

	def yesterday(self) -> str: 
		return datetime.now(timezone.utc).date() - timedelta(1) 
	
	def one_week_ago(self) -> str:
		# add another buffer of 1 day, instead of 8 days ago, use 9 days ago
		return datetime.now(timezone.utc).date() - timedelta(9) 
		
    def rows(self, one_week_ago, yesterday) -> pd.DataFrame:
		"""
		Select from fct_vehicle_locations (partitioned on dt). 
		Parent of fct_vehicle_locations uses the intermediate table that converts dt to service_date,
		so we can use service_date here? 
		(TODO: confirm service_date over dt use for query).
		"""
        selected_columns = ", ".join(self.columns) if self.columns else "*"

        return self.bigquery_hook().get_df(
			sql=f"""
            	SELECT 
					{selected_columns},
					DATETIME(location_timestamp, "America/Los_Angeles") AS location_timestamp_pacific
            	FROM `{self.dataset_name}.{self.table_name}`
            	WHERE service_date >= DATE('{one_week_ago}') AND service_date <= DATE('{yesterday}')
        	""",
			df_type="pandas"
		)
    
    def rows_grouped_by_trip(self, one_week_ago, yesterday) -> pd.DataFrame:
		"""
		Other trip-level rows to save as arrays.
		How would .partial and .expand be used to write this?
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
	            WHERE service_date >= DATE('{one_week_ago}') AND service_date <= DATE('{yesterday}')
				GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	        """,
			df_type="pandas"
		)
		
	def enrich_with_movingpandas_columns(df: pd.DataFrame) -> pd.DataFrame:
		"""
		Convert df into a movingpandas TrajectoryCollection.
		Needs a path grouping column (trip_instance_key), object identifier (vp's key), 
		x, y coordinates as numeric columns,
		and timestamp column that is not UTC.

		Results will keep traj_id_col, obj_id_col, + columns that are added. 
		x, y coordinates and timestamp are dropped within the TrajectoryCollection.
		
		Using UTC location_timestamp gave this:
		TimeZoneWarning: Time zone information dropped from trajectory. All dates and times will use local time. 
		This is applied by doing df.tz_localize(None). 
		To use UTC or a different time zone, convert and drop time zone information prior to trajectory creation.
		"""
		tc = mpd.TrajectoryCollection(
            df, 
            traj_id_col = "trip_instance_key", 
            obj_id_col = "key", 
            x = "position_longitude", 
            y = "position_latitude", 
            t = "location_timestamp_pacific" 
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

		# movingpandas should be returning a sorted df anyway?
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
		movingpandas_df = self.rows().enrich_with_movingpandas_columns()

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
                    "filename": "trajectories.jsonl.gz", # TODO: confirm if filepath looks like BUCKET/destination_path/dt=/trajectories.jsonl.gz
                    "dt": self.dt, # TODO: how to get right partition by dt or service_date? 
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
