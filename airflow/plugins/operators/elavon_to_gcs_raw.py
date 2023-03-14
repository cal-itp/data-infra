import os

import gcsfs
import paramiko

from airflow.models import BaseOperator

CALITP__ELAVON_SFTP_PASSWORD = os.environ["CALITP__ELAVON_SFTP_PASSWORD"]
BIGQUERY_KEYFILE_LOCATION = os.environ["BIGQUERY_KEYFILE_LOCATION"]


def mirror_raw_files_from_elavon():
    """
    Download Elavon transaction records from SFTP and write raw files to GCS for
    further processing in another job
    """

    # Establish connection to SFTP server
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname="34.145.56.125",
        port=2200,
        username="elavon",
        password=CALITP__ELAVON_SFTP_PASSWORD,
    )

    # Create SFTP client and navigate to data directory
    sftp_client = client.open_sftp()
    sftp_client.chdir("/data")

    # Initialize GCS connection
    gfs = gcsfs.GCSFileSystem(
        project="cal-itp-data-infra",
        token=BIGQUERY_KEYFILE_LOCATION,
    )

    for file in [x for x in sftp_client.listdir() if "zip" in x]:
        print(f"Processing file {file}")

        # Save to local directory for mirrored transfer to GCS
        if not os.path.exists("transferred_files"):
            os.mkdir("transferred_files")
        local_path = f"transferred_files/{file}"
        sftp_client.get(file, local_path)

        # We put file by file because recursively putting the directory causes relative
        # filepath issues
        gfs.put(lpath=f"transferred_files/{file}", rpath="gs://test-calitp-elavon-raw/")


class ElavonToGCSRawOperator(BaseOperator):
    def __init__(
        self,
        **kwargs,
    ):
        super().__init__(**kwargs)

    def execute(self, **kwargs):
        mirror_raw_files_from_elavon()
