import os

import gcsfs  # type: ignore[import]


def get_fs(gcs_project="", **kwargs):
    if os.environ.get("CALITP_AUTH") == "cloud":
        return gcsfs.GCSFileSystem(project=gcs_project, token="cloud", **kwargs)
    else:
        return gcsfs.GCSFileSystem(
            project=gcs_project, token="google_default", **kwargs
        )
