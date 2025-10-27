# ---
# python_callable: mirror_raw_files_from_elavon
# provide_context: true
# ---
import os

import paramiko
import pendulum
from calitp_data_infra.auth import get_secret_by_name
from calitp_data_infra.storage import get_fs

CALITP__ELAVON_SFTP_HOSTNAME = os.environ["CALITP__ELAVON_SFTP_HOSTNAME"]
CALITP__ELAVON_SFTP_PORT = os.environ["CALITP__ELAVON_SFTP_PORT"]
CALITP__ELAVON_SFTP_USERNAME = os.environ["CALITP__ELAVON_SFTP_USERNAME"]
CALITP_BUCKET__ELAVON_RAW = os.environ["CALITP_BUCKET__ELAVON_RAW"]


def mirror_raw_files_from_elavon():
    """
    Download Elavon transaction records from SFTP and write raw files to GCS for
    further processing in another job
    """

    # Establish connection to SFTP server
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # nosec B507
    client.connect(
        hostname=CALITP__ELAVON_SFTP_HOSTNAME,
        port=CALITP__ELAVON_SFTP_PORT,
        username=CALITP__ELAVON_SFTP_USERNAME,
        password=get_secret_by_name("CALITP__ELAVON_SFTP_PASSWORD"),
    )

    # Create SFTP client and navigate to data directory
    sftp_client = client.open_sftp()
    sftp_client.chdir("/data")

    # Initialize GCS connection
    fs = get_fs()

    # Initiailize extract time used by all files
    ts = pendulum.now().to_iso8601_string()

    for file in [x for x in sftp_client.listdir() if x.endswith(".zip")]:
        print(f"Processing file {file}")

        # Save to local directory for mirrored transfer to GCS
        if not os.path.exists("transferred_files"):
            os.mkdir("transferred_files")
        local_path = f"transferred_files/{file}"
        sftp_client.get(file, local_path)

        # We put file by file because recursively putting the directory causes relative
        # filepath issues
        fs.put(
            lpath=f"transferred_files/{file}",
            rpath=f"{CALITP_BUCKET__ELAVON_RAW}/ts={ts}/",
        )


if __name__ == "__main__":
    mirror_raw_files_from_elavon()
