# ---
# python_callable: main
# provide_context: true
#
# task_concurrency: 3
#
# dependencies:
#   - load_vehicle_positions
#
# external_dependencies:
#   - rt_timestamp_fix: rename_timestamp_to_datetime
# ---

from google.transit import gtfs_realtime_pb2
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from calitp.storage import get_fs
from concurrent.futures import ThreadPoolExecutor
from collections import defaultdict


import pandas as pd
import tempfile


N_THREADS = 50

SRC_PATH = "gs://gtfs-data/rt/"
DST_PATH = "gtfs-data/rt-processed/vehicle_positions/"


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


def fetch_bucket_file_names(iso_date, fs):
    # posix_date = str(time.mktime(execution_date.timetuple()))[:6]

    # get rt files
    print("Globbing rt bucket...")
    print(SRC_PATH + iso_date + "*")
    rt = fs.glob(SRC_PATH + iso_date + "*")

    buckets_to_parse = len(rt)
    print("Realtime buckets to parse: {i}".format(i=buckets_to_parse))

    # organize rt files by itpId_urlNumber
    rt_files = []
    for r in rt:
        rt_files.append(fs.ls(r))

    vp_files = [
        item for sublist in rt_files for item in sublist if "vehicle_positions" in item
    ]

    feed_files = defaultdict(lambda: [])

    for fname in vp_files:
        itpId, urlNumber = fname.split("/")[-3:-1]
        feed_files[(itpId, urlNumber)].append(fname)

    # Now our feed files dict has a key of itpId_urlNumber and a list of files to parse
    return feed_files


def main(execution_date, **kwargs):
    iso_date = str(execution_date).split("T")[0]

    # fetch files ----
    # for some reason the fs.glob command takes up a fair amount of memory here,
    # and does not seem to free it after the function returns, so we manually clear
    # its caches (at lest the ones I could find)
    fs = get_fs()
    feed_files = fetch_bucket_file_names(iso_date, fs)
    fs.dircache.clear()

    # parse feeds ----
    for feed, files in feed_files.items():
        itp_id_url_num = "_".join(map(str, feed))
        file_name = f"vp_{iso_date}_{itp_id_url_num}.parquet"
        print("Creating " + file_name)
        print("  parsing %s files" % len(files))

        if len(files) > 0:
            # partial parse_pb for running async
            with ThreadPoolExecutor(N_THREADS) as pool:
                parsed_positions = list(
                    pool.map(lambda f: parse_pb(f, open_with=fs.open), files)
                )

            positions_dfs = [*map(rectangle_positions, parsed_positions)]
            positions_dfs = [df for df in positions_dfs if df is not None]

            print("  %s positions sub dataframes created" % len(positions_dfs))
            if len(positions_dfs) > 0:
                positions_rectangle = pd.concat(positions_dfs)
                positions_rectangle.insert(0, "calitp_itp_id", feed[0])
                positions_rectangle.insert(1, "calitp_url_number", feed[1])

                with tempfile.TemporaryDirectory() as tmpdirname:
                    fname = tmpdirname + "/" + "temporary" + ".parquet"
                    positions_rectangle.to_parquet(fname, index=False)
                    fs.put(
                        fname, DST_PATH + file_name,
                    )
