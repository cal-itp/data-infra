import gcsfs  # type: ignore

from .config import is_cloud


def get_fs(gcs_project="", **kwargs):
    if is_cloud():
        return gcsfs.GCSFileSystem(project=gcs_project, token="cloud", **kwargs)
    else:
        return gcsfs.GCSFileSystem(
            project=gcs_project, token="google_default", **kwargs
        )
