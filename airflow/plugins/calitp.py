"""This module holds high-level functions for opening and saving data.

"""


import os
import gcsfs

from pathlib import Path


def is_development():
    return os.environ["COMPOSER_ENVIRONMENT"] == "development"


def pipe_file_name(path):
    """Returns absolute path for a file in the pipeline (e.g. the data folder).

    """

    # For now, we just get the path relative to the directory holding the
    # DAGs folder. For some reason, gcp doesn't expose the same variable
    # for this folder, so need to handle differently on dev.
    if is_development():
        root = Path(os.environ["AIRFLOW__CORE__DAGS_FOLDER"]).parent
    else:
        root = Path(os.environ["DAG_DIRECTORY"]).parent

    return str(root / path)


def save_to_gcfs(src_path, dst_path, gcs_project="cal-itp-data-infra", **kwargs):
    """Convenience function for saving files from disk to google cloud storage.

    Arguments:
        src_path: path to file being saved.
        dst_path: path to bucket subdirectory (e.g. "path/to/dir").
    """

    if is_development():
        bucket = Path("gs://gtfs-data-test")
    else:
        bucket = Path("gs://gtfs-data")

    fs = gcsfs.GCSFileSystem(project=gcs_project, token="cloud")
    fs.put(str(src_path), str(bucket / dst_path), **kwargs)
