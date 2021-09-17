from airflow.models import BaseOperator
from google.transit import gtfs_realtime_pb2
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from calitp.storage import get_fs
import pandas as pd
import tempfile
import time


def parse_pb(path, open_with=None):
    """
    Convert pb file to Python dictionary
    """
    open_func = open_with if open_with is not None else open
    feed = gtfs_realtime_pb2.FeedMessage()
    try:
        feed.ParseFromString(open_func(path, "rb").read())
        d = json_format.MessageToDict(feed)
    except DecodeError:
        d = {}
    d.update({"calitp_filepath": path})
    return d


def pull_value(x, path):
    """
    Safe extraction for pulling entity values
    """
    crnt_obj = x
    for attr in path.split("."):
        try:
            crnt_obj = crnt_obj[attr]
        except KeyError:
            return None
    return crnt_obj


def get_header_details(x):
    """
    Returns a dictionary of header values to be added to a dataframe
    """
    return {
        "header_timestamp": pull_value(x, "header.timestamp"),
        "calitp_filepath": pull_value(x, "calitp_filepath"),
    }


def get_entity_details(x):
    """
    Returns a list of dicts containing entity values to be added to a dataframe
    """
    entity = x.get("entity")
    details = []
    if entity is not None:
        for e in entity:
            d = {
                "entity_id": pull_value(e, "id"),
                "vehicle_id": pull_value(e, "vehicle.vehicle.id"),
                "vehicle_trip_id": pull_value(e, "vehicle.trip.tripId"),
                "vehicle_timestamp": pull_value(e, "vehicle.timestamp"),
                "vehicle_position_latitude": pull_value(e, "vehicle.position.latitude"),
                "vehicle_position_longitude": pull_value(
                    e, "vehicle.position.longitude"
                ),
            }
            details.append(d)
    return details


def rectangle_positions(x):
    """
    Create a vehicle positions dataframe from parsed pb files
    """
    header_details = get_header_details(x)
    entity_details = get_entity_details(x)
    if len(entity_details) > 0:
        rectangle = pd.DataFrame(entity_details)
        for k, v in header_details.items():
            rectangle[k] = v
        return rectangle
    else:
        return None


class ParseRtOperator(BaseOperator):
    def __init__(
        self,
        source_bucket="gs://gtfs-data/rt/",
        destination_bucket="gtfs-data/rt-processed/vehicle_positions/",
        **kwargs,
    ):

        self.source_bucket = source_bucket
        self.destination_bucket = destination_bucket
        super().__init__(**kwargs)

    def execute(self, context):

        # convert execution date to posix date
        execution_date = context["execution_date"]
        posix_date = str(time.mktime(execution_date.timetuple()))[:6] + "*"

        # get rt files
        rt_bucket = self.source_bucket
        print("Globbing rt bucket...")
        print(rt_bucket + posix_date)
        fs = get_fs()
        rt = fs.glob(rt_bucket + posix_date)
        buckets_to_parse = len(rt)
        print("Realtime buckets to parse: {i}".format(i=buckets_to_parse))

        counter = 0
        for r in rt:
            print("---")
            counter += 1
            print("{n} of {t}: {r}".format(n=counter, t=buckets_to_parse, r=r))
            bucket_list = fs.ls(r)
            position_files = [i for i in bucket_list if "vehicle_positions" in i]
            print("Positions files: {n}".format(n=len(position_files)))
            if len(position_files) > 0:
                parsed_positions = [
                    parse_pb(f, open_with=fs.open) for f in position_files
                ]
                positions_dfs = [*map(rectangle_positions, parsed_positions)]
                positions_dfs = [df for df in positions_dfs if df is not None]
                if len(positions_dfs) > 0:
                    positions_rectangle = pd.concat(positions_dfs)
                    with tempfile.TemporaryDirectory() as tmpdirname:
                        fname = tmpdirname + "/" + r.split("/")[-1] + ".parquet"
                        positions_rectangle.to_parquet(fname, index=False)
                        fs.put(fname, self.destination_bucket + fname.split("/")[-1])
