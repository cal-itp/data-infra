import gcsfs  # type: ignore
import geopandas  # type: ignore
import pytest
from calitp_data_analysis.gcs_geopandas import GCSGeoPandas

TOKEN = "faketoken"
PATH = "https://www.example.com/path/to/file"
ANY_OTHER_ARGUMENT = "fakeargument"
GCS_FILESYSTEM = "fakegcsfilesystem"


@pytest.fixture
def gcs_geopandas(mocker):
    return GCSGeoPandas()


@pytest.fixture
def gcs_auth_setup(mocker):
    mocker.patch("google.auth.default", return_value=(TOKEN, None))


def test_gcs_filesystem(mocker, gcs_auth_setup, gcs_geopandas):
    mocker.patch("gcsfs.GCSFileSystem")

    gcs_geopandas.gcs_filesystem()

    gcsfs.GCSFileSystem.assert_called_once_with(token=TOKEN)


def test_read_parquet(mocker, gcs_auth_setup, gcs_geopandas):
    mocker.patch("geopandas.read_parquet")

    gcs_geopandas.read_parquet(PATH, ANY_OTHER_ARGUMENT)

    geopandas.read_parquet.assert_called_once_with(
        PATH, ANY_OTHER_ARGUMENT, storage_options={"token": TOKEN}
    )


def test_read_parquet_passed_storage_options(mocker, gcs_auth_setup, gcs_geopandas):
    mocker.patch("geopandas.read_parquet")

    gcs_geopandas.read_parquet(PATH, ANY_OTHER_ARGUMENT, storage_options={"foo": "bar"})

    geopandas.read_parquet.assert_called_once_with(
        PATH, ANY_OTHER_ARGUMENT, storage_options={"foo": "bar", "token": TOKEN}
    )


def test_geo_data_frame_to_parquet(mocker, gcs_auth_setup, gcs_geopandas):
    mocker.patch("gcsfs.GCSFileSystem", return_value=GCS_FILESYSTEM)
    geo_data_frame = mocker.create_autospec(geopandas.GeoDataFrame)

    gcs_geopandas.geo_data_frame_to_parquet(geo_data_frame, PATH, ANY_OTHER_ARGUMENT)

    gcsfs.GCSFileSystem.assert_called_once_with(token=TOKEN)
    geo_data_frame.to_parquet.assert_called_once_with(
        PATH, ANY_OTHER_ARGUMENT, filesystem=GCS_FILESYSTEM
    )
