# ---
# python_callable: gen_list
# ---


import yaml
import pandas as pd


def make_gtfs_list():
    """
    Read in a list of GTFS urls
    from the main db
    plus metadata
    kwargs:
     catalog = a intake catalog containing an "official_list" item.
    """

    agencies = yaml.safe_load(open("data/agencies.yml"))

    # yaml has form <agency_name>: { agency_name: "", gtfs_schedule_url: [...,] }
    df = pd.DataFrame.from_dict(agencies, orient="index")

    # TODO: handle multiple urls
    # currently stores urls as a list, so get first (and hopefully only) entry
    df["gtfs_schedule_url"] = df["gtfs_schedule_url"].str.get(0)

    # TODO: Figure out what to do with Metro
    # For now, we just take the bus.

    # TODO: Replace URLs with Zip ones.
    # For now we filter, and then remove ones that don't contain
    # zip filters
    df = df[(df.gtfs_schedule_url.str.contains("zip")) & (df.gtfs_schedule_url.notna())]
    return df


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
