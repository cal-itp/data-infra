import pandas as pd
from calitp_data_analysis import get_fs


class GCSPandas:
    """
    GCSPandas contains authentication helpers for interacting with Google Cloud Storage with Pandas
    """

    def __init__(self, **kwargs):
        """Fetches and sets instance Google Cloud Storage Filesystem"""
        self.gcs_filesystem = get_fs(**kwargs)

    def read_parquet(self, path, *args, **kwargs):
        """Delegates to pd.read_parquet with gcs_filesystem"""
        return pd.read_parquet(path, filesystem=self.gcs_filesystem, *args, **kwargs)

    def read_csv(self, path, **kwargs):
        """Delegates to pd.read_csv with the file at the path specified in the GCS filesystem"""
        with self.gcs_filesystem.open(path) as file:
            data_frame = pd.read_csv(file, **kwargs)

        return data_frame

    def read_excel(self, path, **kwargs):
        """Delegates to pd.read_excel with the file at the path specified in the GCS filesystem"""
        with self.gcs_filesystem.open(path) as file:
            data_frame = pd.read_excel(file, **kwargs)

        return data_frame

    def data_frame_to_parquet(self, data_frame, path, **kwargs):
        """Delegates to data_frame.to_parquet, with Google Cloud Storage filesystem"""
        return data_frame.to_parquet(path, filesystem=self.gcs_filesystem, **kwargs)
