def map_agencies_urls(logger, yaml_data):

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
                if feed_name.startswith("gtfs_rt") and feed_url:

                    agency_itp_id = agency_def["itp_id"]
                    feed_id = "{}/{}/{}".format(agency_itp_id, i, feed_name)
                    yield feed_id, feed_url


def map_headers(logger, yaml_data):

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
