def parse_agencies_urls(logger, datasrc_data):

    for agency_name, agency_def in datasrc_data.items():

        if "feeds" not in agency_def:
            logger.warning(
                "agency {}: skipped loading "
                "invalid definition (missing feeds)".format(agency_name)
            )
            continue

        if "itp_id" not in agency_def:
            logger.warning(
                "agency {}: skipped loading "
                "invalid definition (missing itp_id)".format(agency_name)
            )
            continue

        for i, feed_set in enumerate(agency_def["feeds"]):
            for feed_name, feed_url in feed_set.items():
                if feed_name.startswith("gtfs_rt") and feed_url:

                    agency_itp_id = agency_def["itp_id"]
                    data_name = "{}/{}/{}".format(agency_itp_id, i, feed_name)
                    yield ( data_name, feed_url )
