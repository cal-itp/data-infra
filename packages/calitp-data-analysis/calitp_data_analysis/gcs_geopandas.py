import gcsfs  # type: ignore
import geopandas as gpd  # type: ignore
import google.auth  # type: ignore


class GCSGeoPandas:
    """
    GCSGeoPandas contains authentication helpers for interacting with Google Cloud   Storage with GeoPandas
    """

    def __init__(self):
        """Sets instance token to credentials returned from Google auth request"""
        credentials, _ = google.auth.default()
        self.token = credentials

    def gcs_filesystem(self, **kwargs):
        """Returns a Google Cloud Storage Filesystem"""
        return gcsfs.GCSFileSystem(token=self.token, **kwargs)

    def read_parquet(self, path, *args, **kwargs):
        """Delegates to gpd.read_parquet with storage option token

        Passes the auth credentials from Google auth as storage option token
        """
        storage_options = kwargs.pop("storage_options", {}) | {"token": self.token}

        return gpd.read_parquet(path, storage_options=storage_options, *args, **kwargs)

    def geo_data_frame_to_parquet(self, geo_data_frame, path, *args, **kwargs):
        """Delegates to .to_parquet on the passed geo_data_frame, providing Google Cloud Storage file system

        Fetches gcsfs.GCSFileSystem instance and then delegates to .to_parquet passing the filesystem info
        """
        gcs_filesystem = self.gcs_filesystem()
        return geo_data_frame.to_parquet(
            path, filesystem=gcs_filesystem, *args, **kwargs
        )
