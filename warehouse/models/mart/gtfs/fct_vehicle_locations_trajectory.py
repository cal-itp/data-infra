"""
Set up Python data model to using movingpandas with fct_vehicle_locations
to add distance (meters elapsed), speed, acceleration,
angular difference, and direction to our existing mart table.

Python data models use BigFrames.

Ex 1: (simple, create table)
https://github.com/googleapis/python-bigquery-dataframes/blob/main/samples/dbt/dbt_sample_project/models/example/dbt_bigframes_code_sample_1.py

Ex 2: (create incremental models)
https://github.com/googleapis/python-bigquery-dataframes/blob/main/samples/dbt/dbt_sample_project/models/example/dbt_bigframes_code_sample_2.py

Ex 3: using bigframes (bpd)
https://github.com/googleapis/python-bigquery-dataframes/blob/main/samples/dbt/dbt_sample_project/models/ml_example/prepare_table.py
"""
import bigframes.pandas as bpd  # is this one necessary?
import movingpandas as mpd
import pandas as pd

"""
# save as "cal-itp-data-infra-staging.mart_gtfs.fct_vehicle_locations_sample"
SELECT
  *
FROM `cal-itp-data-infra-staging.mart_gtfs.fct_vehicle_locations`
WHERE dt >= "2025-10-23"

# dt available were: 2025-10-23 through 2025-10-26 inclusive
53,377,780 rows
can work out whether incremental strategy works
"""


def model(dbt, session):
    """
    Use `fct_vehicle_locations`, group by trip (`trip_instance_key`), and use
    `location`, `location_timestamp` in movingpandas TrajectoryCollection.
    Add distance and time elapsed (distance_meters, timedelta_seconds),
    speed_mph, acceleration_mph_per_sec, angular_difference, and direction.
    https://movingpandas.github.io/movingpandas-website/1-tutorials/2-computing-speed.html
    """
    # Optional: Override settings from your dbt_project.yml file.
    # When both are set, dbt.config takes precedence over dbt_project.yml.

    dbt.config(
        # Use BigFrames mode to execute this Python model. This enables
        # pandas-like operations directly on BigQuery data.
        submission_method="bigframes",
        materialized="table",
        # As of Nov 2025: Incremental Python models support all the same incremental strategies as their SQL counterparts.
        # As of Mar 2026: does switching from general incremental -> microbatch matter?
        # Use dt to align with microbatch, forget service_date for now.
        # set package versions to be what is currently in main JupyterHub image (not prototype)
        packages=["movingpandas==0.22.4", "pandas==2.3.3"],
        notebook_template_id=None,
    )

    # Define the BigQuery table path from which to read data (how to grab each dt incrementally?).
    # table = "cal-itp-data-infra.mart_gtfs.fct_vehicle_locations"
    # partitioned by dt, clustered by dt, base64_url

    table = "cal-itp-data-infra-staging.mart_gtfs.fct_vehicle_locations_sample"

    # Define the specific columns to select from the BigQuery table.
    columns = [
        "key",
        "dt",
        "service_date",
        "base64_url",
        "trip_instance_key",
        "position_longitude",  # movingpandas takes x, y coordinates, not location
        "position_latitude",
        "location_timestamp",  # this is UTC, but since timedelta is converted to seconds, it doesn't matter
    ]

    # Read data from the specified BigQuery table into a BigFrames DataFrame.
    df = session.read_gbq(table, columns=columns)

    # Take df and make into movingpandas.TrajectoryCollection, then
    # add all the columns we can for all rows present in fct_vehicle_locations.
    # We should keep partition + cluster columns + vp_key to join it back to fct_vehicle_locations.
    tc = mpd.TrajectoryCollection(
        df,
        traj_id_col="trip_instance_key",
        obj_id_col="key",
        x="position_longitude",
        y="position_latitude",
        t="location_timestamp",
    )

    # Add all the columns we can add
    tc.add_distance(overwrite=True, name="distance_meters", units="m")
    tc.add_timedelta(overwrite=True)
    tc.add_speed(overwrite=True, name="speed_mph", units=("mi", "h"))
    tc.add_acceleration(
        overwrite=True, name="acceleration_mph_per_sec", units=("mi", "h", "s")
    )
    tc.add_angular_difference(overwrite=True)
    tc.add_direction(overwrite=True)

    result = pd.concat(
        [traj.df.drop(columns="geometry") for traj in tc], axis=0, ignore_index=True
    )

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

    # do we have to coerce the result into a bigframes df explicitly
    # before writing it into a BQ table or can it return result
    return bpd.DataFrame(result)
