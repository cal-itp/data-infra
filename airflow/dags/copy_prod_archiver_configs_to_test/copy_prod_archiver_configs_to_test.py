import os

from calitp_data_infra.storage import GTFSDownloadConfigExtract, get_fs, get_latest

prod_bucket = os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_PROD")
test_bucket = os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG")

extract = get_latest(GTFSDownloadConfigExtract, prod_bucket)

fs = get_fs()

if __name__ == "__main__":
    fs.copy(prod_bucket + "/" + extract.name, test_bucket + "/" + extract.name)
