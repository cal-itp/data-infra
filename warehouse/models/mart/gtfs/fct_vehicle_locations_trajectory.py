"""
Set up Python data model using movingpandas with fct_vehicle_locations
to add distance (meters elapsed), speed, acceleration,
angular difference, and direction to our existing mart table.

Python data model runs on Dataproc Serverless (PySpark) via applyInPandas,
which fans out one pandas partition per trip_instance_key.
movingpandas==0.22.4 is pre-installed in the Dataproc container image.
"""
import movingpandas as mpd
import pandas as pd
from pyspark.sql import functions as F  # noqa: F401
from pyspark.sql import types as T


def model(dbt, session):
    """
    Use `fct_vehicle_locations`, group by trip (`trip_instance_key`), and use
    `position_longitude`, `position_latitude`, `location_timestamp` in a
    movingpandas TrajectoryCollection (one per trip) via applyInPandas.
    Add distance and time elapsed (distance_meters, timedelta_seconds),
    speed_mph, acceleration_mph_per_sec, angular_difference, and direction.
    https://movingpandas.github.io/movingpandas-website/1-tutorials/2-computing-speed.html
    """
    dbt.config(
        materialized="table",
        packages=["movingpandas==0.22.4"],
    )

    columns = [
        "key",
        "dt",
        "service_date",
        "base64_url",
        "trip_instance_key",
        "position_longitude",  # movingpandas takes x, y coordinates, not location
        "position_latitude",
        "location_timestamp",  # UTC; timedelta is converted to seconds so tz doesn't matter
    ]

    from datetime import timedelta

    source = dbt.ref("fct_vehicle_locations_no_interval")
    max_dt = source.agg(F.max("dt")).collect()[0][0]
    cutoff = max_dt - timedelta(days=5)

    df = source.select(*columns).filter(F.col("dt") >= F.lit(cutoff))

    output_schema = T.StructType(
        [
            T.StructField("key", T.StringType()),
            T.StructField("dt", T.DateType()),
            T.StructField("service_date", T.DateType()),
            T.StructField("base64_url", T.StringType()),
            T.StructField("trip_instance_key", T.StringType()),
            T.StructField("position_longitude", T.DoubleType()),
            T.StructField("position_latitude", T.DoubleType()),
            T.StructField("location_timestamp", T.TimestampType()),
            T.StructField("distance_meters", T.FloatType()),
            T.StructField("timedelta_seconds", T.FloatType()),
            T.StructField("speed_mph", T.FloatType()),
            T.StructField("acceleration_mph_per_sec", T.FloatType()),
            T.StructField("angular_difference", T.FloatType()),
            T.StructField("direction", T.FloatType()),
        ]
    )

    def process_trajectory(pdf: pd.DataFrame) -> pd.DataFrame:
        if len(pdf) < 2:
            return pd.DataFrame(columns=[field.name for field in output_schema.fields])

        tc = mpd.TrajectoryCollection(
            pdf,
            traj_id_col="trip_instance_key",
            obj_id_col="key",
            x="position_longitude",
            y="position_latitude",
            t="location_timestamp",
        )

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
            timedelta_seconds=result.timedelta.dt.total_seconds(),
        )
        result = result.drop(columns=["timedelta"])

        return result[[field.name for field in output_schema.fields]]

    result = df.groupBy("trip_instance_key").applyInPandas(
        process_trajectory, schema=output_schema
    )

    return result
