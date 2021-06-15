# ---
# python_callable: gen_list
# ---


import yaml
import pandas as pd

from calitp import pipe_file_name


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
    df_final = df_long.join(df_feeds).drop(
        columns=[
            "feeds",
            "gtfs_rt_vehicle_positions",
            "gtfs_rt_service_alerts_url",
            "gtfs_rt_trip_updates_url",
        ]
    )
    df_final["url_number"] = df_final.groupby("itp_id").cumcount()

    return df_final


def clean_url(url):
    """
    take the list of urls, clean as needed.
    used as a pd.apply, so singleton.
    """
    # LA Metro split requires lstrip
    return url


def gen_list(**kwargs):
    """
    task callable to generate the list and push into
    xcom
    """
    provider_set = make_gtfs_list().apply(clean_url)
    return provider_set.to_dict("records")
