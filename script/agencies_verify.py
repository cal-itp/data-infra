import logging
import sys

import requests
import yaml
from requests import HTTPError

USAGE = """
Usage:
python script/agencies_verify.py agencies.yml headers.yml [DIFF]

Arguments:
agencies.yml - Yaml file containing agencies to download
headers.yml - Yaml file mapping headers onto urls in agencies.yml
DIFF - optional git diff between two hashes (will check all urls if not provided)
"""

"""
Functions which map data from a yaml file into a YamlMapper map

Interface for mapperfn:

Parameters
----------
logger : logging.Logger
    The program logger
yaml_data : object
    Data as returned by yaml.load from the YamlMapper file

Yields
------
map_key : str
    The identifier which the yaml data should be mapped to
map_data : object
    Data or scalar which should map back to the key
"""


def map_agencies_urls(logger, yaml_data, key_prefix="gtfs_rt"):
    """Maps unique identifiers to GTFS-RT feed urls from an agencies.yml

    Each URL is mapped to an identifier which is a combination of its agency id, its
    index position, and the type/name of the RT feed (e.g.,
    gtfs_rt_vehicle_positions_url, gtfs_rt_alerts_url, etc).
    """
    for agency_name, agency_def in yaml_data.items():

        if "feeds" not in agency_def:
            logger.error(
                "agency {}: skipped loading "
                "invalid definition (missing feeds)".format(agency_name)
            )
            continue

        if "itp_id" not in agency_def:
            logger.error(
                "agency {}: skipped loading "
                "invalid definition (missing itp_id)".format(agency_name)
            )
            continue

        for i, feed_set in enumerate(agency_def["feeds"]):
            for feed_name, feed_url in feed_set.items():
                if feed_name.startswith(key_prefix) and feed_url:

                    agency_itp_id = agency_def["itp_id"]
                    feed_id = "{}/{}/{}".format(agency_itp_id, i, feed_name)
                    yield feed_id, feed_url


def map_headers(logger, yaml_data):
    """Maps unique identifiers to header data from a headers.yml

    Each map_key yieldeed by this mapperfn corresponds to a map_key names which is
    yielded by map_agencies_urls
    """
    seen = set()
    for item in yaml_data:
        for url_set in item["URLs"]:
            itp_id = url_set["itp_id"]
            url_number = url_set["url_number"]
            for rt_url in url_set["rt_urls"]:
                feed_id = f"{itp_id}/{url_number}/{rt_url}"
                if feed_id in seen:
                    raise ValueError(
                        f"Duplicate header data for url with feed_id: {feed_id}"
                    )
                seen.add(feed_id)
                yield feed_id, item["header-data"]

    logger.debug(f"Header file successfully mapped with {len(seen)} entries")


def main():
    logger = logging.getLogger("gtfs-rt-archive")
    successes = []
    fails = []
    changed_urls = None

    with open(sys.argv[1], "r") as f:
        agencies_yaml = yaml.load(f, Loader=yaml.SafeLoader)
        agencies = map_agencies_urls(logger, agencies_yaml, key_prefix="gtfs_")
    with open(sys.argv[2], "r") as f:
        headers = dict(list(map_headers(logger, yaml.load(f, Loader=yaml.SafeLoader))))
    if len(sys.argv) > 3:
        with open(sys.argv[3], "r") as f:
            lines = f.readlines()
            lines = [line for line in lines if line.startswith("+") and "http" in line]
            changed_urls = ["http" + line.strip().split("http")[-1] for line in lines]

    for key, url in list(agencies):
        if changed_urls is not None and url not in changed_urls:
            continue
        try:
            h = {
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:55.0) Gecko/20100101 Firefox/55.0",
                **headers.get(key, {}),
            }

            print(f"attempting to download {key}")
            result = requests.get(url, headers=h, timeout=10)
            result.raise_for_status()
        except Exception as e:
            print(f"Failed to download {key}")
            reason = f"Reason: {type(e)}"
            if isinstance(e, HTTPError):
                reason = f"{reason}({e.response.status_code})"
            print(reason)
            fails.append(url)
            continue
        successes.append(url)
    print(f"{len(successes)}/{len(successes+fails)} urls successfully downloaded")
    if fails:
        print("Exiting with error because some urls failed to download")
        exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(USAGE)
        exit(1)
    main()
