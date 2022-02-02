"""mapperfns.py: Functions which map data from a yaml file into a YamlMapper map

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
