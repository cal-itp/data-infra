import io

import gcsfs  # type: ignore
import geopandas as gpd  # type: ignore
import pytest
from calitp_data_analysis.gcs_geopandas import GCSGeoPandas


class TestGCSGeoPandas:
    @pytest.fixture
    def path(self):
        return "https://www.example.com/path/to/file"

    @pytest.fixture
    def any_other_argument(self):
        return "fakeargument"

    @pytest.fixture
    def gcs_geopandas(self):
        return GCSGeoPandas()

    @pytest.fixture
    def gcs_filesystem(self, mocker):
        return mocker.create_autospec(gcsfs.GCSFileSystem, instance=True)

    @pytest.fixture
    def gcs_filesystem_setup(self, mocker, gcs_filesystem):
        mocker.patch("gcsfs.GCSFileSystem", return_value=gcs_filesystem)

    def test_read_parquet(
        self,
        mocker,
        path,
        any_other_argument,
        gcs_filesystem,
        gcs_filesystem_setup,
        gcs_geopandas,
    ):
        geo_data_frame = mocker.create_autospec(gpd.GeoDataFrame)
        mocker.patch("geopandas.read_parquet", return_value=geo_data_frame)

        result = gcs_geopandas.read_parquet(path, anything=any_other_argument)

        gpd.read_parquet.assert_called_once_with(
            path, filesystem=gcs_filesystem, anything=any_other_argument
        )

        assert result == geo_data_frame

    def test_read_file(
        self,
        mocker,
        gcs_filesystem,
        gcs_filesystem_setup,
        gcs_geopandas,
        path,
        any_other_argument,
    ):
        file = io.StringIO("fakefile")
        geo_data_frame = mocker.create_autospec(gpd.GeoDataFrame)
        mocker.patch("geopandas.read_file", return_value=geo_data_frame)
        gcs_filesystem.open.return_value = file

        result = gcs_geopandas.read_file(path, anything=any_other_argument)

        gcs_filesystem.open.assert_called_once_with(path)
        gpd.read_file.assert_called_once_with(file, anything=any_other_argument)

        assert result == geo_data_frame

    def test_geo_data_frame_to_parquet(
        self,
        mocker,
        path,
        any_other_argument,
        gcs_filesystem,
        gcs_filesystem_setup,
        gcs_geopandas,
    ):
        geo_data_frame = mocker.create_autospec(gpd.GeoDataFrame)

        gcs_geopandas.geo_data_frame_to_parquet(
            geo_data_frame, path, anything=any_other_argument
        )

        geo_data_frame.to_parquet.assert_called_once_with(
            path, filesystem=gcs_filesystem, anything=any_other_argument
        )
