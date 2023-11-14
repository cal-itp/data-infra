# ---
# python_callable: copy_config
# provide_context: true
# ---

import os

from calitp_data_infra.storage import GTFSDownloadConfigExtract, get_fs, get_latest

prod_bucket = os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_PROD_SOURCE")
test_bucket = os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_TEST_DESTINATION")


def copy_config():
    extract = get_latest(GTFSDownloadConfigExtract, prod_bucket)

    fs = get_fs()

    fs.copy(prod_bucket + "/" + extract.name, test_bucket + "/" + extract.name)
