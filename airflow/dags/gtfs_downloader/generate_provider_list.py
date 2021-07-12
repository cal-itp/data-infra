# ---
# python_callable: gen_list
# provide_context: true
# ---


import yaml
import pandas as pd

from calitp.config import pipe_file_name
from calitp import save_to_gcfs


def make_gtfs_list(fname=None):
    """
    Read in a list of GTFS urls
    from the main db
    plus metadata
    kwargs:
     catalog = a intake catalog containing an "official_list" item.
    """

    if fname is None:
        fname = pipe_file_name("data/agencies.yml")

    agencies = yaml.safe_load(open(fname))

    # has form <handle>: { agency_name: "", feeds: [{gtfs_schedule_url: "", ...}]
    df = pd.DataFrame.from_dict(agencies, orient="index")

    assert df.itp_id.is_unique

    # melt feeds to be in long format
    df_long = df.explode("feeds").rename_axis(index="agency_handle").reset_index()

    # make the url feeds into a DataFrame
    df_feeds = pd.DataFrame(df_long.feeds.tolist())
    assert df_feeds.index.equals(df_long.index)

    # append columns for feed urls
    df_feed_urls = df_long.join(df_feeds).drop(columns=["feeds"])
    df_feed_urls["url_number"] = df_feed_urls.groupby("itp_id").cumcount()

    all_cols = list(df_feed_urls.columns)
    front_cols = ["itp_id", "url_number"]
    other_cols = [name for name in all_cols if name not in front_cols]
    return df_feed_urls[[*front_cols, *other_cols]]


def gen_list(execution_date, **kwargs):
    """
    task callable to generate the list and push into
    xcom
    """

    # get a table of feed urls from agencies.yml
    # we fetch both the raw and filled w/ API key versions to save
    feeds_raw = make_gtfs_list(pipe_file_name("data/agencies_raw.yml"))
    feeds = make_gtfs_list(pipe_file_name("data/agencies.yml"))

    path_metadata = f"schedule/{execution_date}/metadata"

    save_to_gcfs(
        feeds_raw.to_csv(index=False).encode(),
        f"{path_metadata}/feeds_raw.csv",
        use_pipe=True,
    )
    save_to_gcfs(
        feeds.to_csv(index=False).encode(), f"{path_metadata}/feeds.csv", use_pipe=True
    )

    # note that right now we useairflow's xcom functionality in this dag.
    # because xcom can only store a small amount of data, we have to drop some
    # columns. this is the only dag that uses xcom, and we should remove it!
    df_subset = feeds.drop(
        columns=[
            "gtfs_rt_vehicle_positions_url",
            "gtfs_rt_service_alerts_url",
            "gtfs_rt_trip_updates_url",
        ]
    )

    return df_subset.to_dict("records")
