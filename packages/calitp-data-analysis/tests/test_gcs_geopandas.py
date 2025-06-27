import io

import gcsfs  # type: ignore
import geopandas as gpd  # type: ignore
import pytest
from calitp_data_analysis.gcs_geopandas import GCSGeoPandas

PATH = "https://www.example.com/path/to/file"
ANY_OTHER_ARGUMENT = "fakeargument"


@pytest.fixture
def gcs_geopandas():
    return GCSGeoPandas()


@pytest.fixture
def gcs_filesystem(mocker):
    return mocker.create_autospec(gcsfs.GCSFileSystem, instance=True)


@pytest.fixture
def gcs_filesystem_setup(mocker, gcs_filesystem):
    mocker.patch("gcsfs.GCSFileSystem", return_value=gcs_filesystem)


def test_read_parquet(mocker, gcs_filesystem, gcs_filesystem_setup, gcs_geopandas):
    geo_data_frame = mocker.create_autospec(gpd.GeoDataFrame)
    mocker.patch("geopandas.read_parquet", return_value=geo_data_frame)

    result = gcs_geopandas.read_parquet(PATH, ANY_OTHER_ARGUMENT)

    gpd.read_parquet.assert_called_once_with(
        PATH, ANY_OTHER_ARGUMENT, filesystem=gcs_filesystem
    )

    assert result == geo_data_frame


def test_read_file(mocker, gcs_filesystem, gcs_filesystem_setup, gcs_geopandas):
    file = io.StringIO("fakefile")
    geo_data_frame = mocker.create_autospec(gpd.GeoDataFrame)
    mocker.patch("geopandas.read_file", return_value=geo_data_frame)
    gcs_filesystem.open.return_value = file

    result = gcs_geopandas.read_file(PATH, ANY_OTHER_ARGUMENT)

    gcs_filesystem.open.assert_called_once_with(PATH)
    gpd.read_file.assert_called_once_with(file)

    assert result == geo_data_frame


def test_geo_data_frame_to_parquet(
    mocker, gcs_filesystem, gcs_filesystem_setup, gcs_geopandas
):
    geo_data_frame = mocker.create_autospec(gpd.GeoDataFrame)

    gcs_geopandas.geo_data_frame_to_parquet(geo_data_frame, PATH, ANY_OTHER_ARGUMENT)

    geo_data_frame.to_parquet.assert_called_once_with(
        PATH, ANY_OTHER_ARGUMENT, filesystem=gcs_filesystem
    )
