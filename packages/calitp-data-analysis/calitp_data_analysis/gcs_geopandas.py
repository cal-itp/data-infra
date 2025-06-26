import geopandas as gpd  # type: ignore
from calitp_data_analysis import get_fs


class GCSGeoPandas:
    """
    GCSGeoPandas contains authentication helpers for interacting with Google Cloud   Storage with GeoPandas
    """

    def __init__(self, **kwargs):
        """Fetches and sets instance Google Cloud Storage Filesystem"""
        self.gcs_filesystem = get_fs(**kwargs)

    def read_parquet(self, path, *args, **kwargs):
        """Delegates to gpd.read_parquet with gcs_filesystem"""
        return gpd.read_parquet(path, filesystem=self.gcs_filesystem, *args, **kwargs)

    def geo_data_frame_to_parquet(self, geo_data_frame, path, *args, **kwargs):
        """Delegates to geo_data_frame.to_parquet, with Google Cloud Storage filesystem"""
        return geo_data_frame.to_parquet(
            path, filesystem=self.gcs_filesystem, *args, **kwargs
        )
