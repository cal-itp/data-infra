# ---
# python_callable: main
# provide_context: true
# external_dependencies:
#   - gtfs_downloader: download_data
# ---

from calitp import read_gcfs, get_bucket, save_to_gcfs
import pandas as pd
import gcsfs


def main(execution_date, **kwargs):
    # TODO: remove hard-coded project string
    fs = gcsfs.GCSFileSystem(project="cal-itp-data-infra")

    bucket = get_bucket()

    f = read_gcfs(f"schedule/{execution_date}/status.csv")
    status = pd.read_csv(f)

    success = status[lambda d: d.status == "success"]

    gtfs_files = []
    for ii, row in success.iterrows():
        agency_folder = f"{row.itp_id}_{row.url_number}"
        gtfs_url = f"{bucket}/schedule/{execution_date}/{agency_folder}/*"

        gtfs_files.append(fs.glob(gtfs_url))

    res = (
        success[["itp_id", "url_number"]]
        .assign(gtfs_file=gtfs_files)
        .explode("gtfs_file")
        .loc[lambda d: d.gtfs_file != "processed"]
    )

    save_to_gcfs(
        res.to_csv(index=False).encode(),
        f"schedule/{execution_date}/processed/files.csv",
        use_pipe=True,
    )
