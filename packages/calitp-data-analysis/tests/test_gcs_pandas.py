import io

import gcsfs  # type: ignore
import pandas as pd  # type: ignore
import pytest
from calitp_data_analysis.gcs_pandas import GCSPandas


class TestGCSPandas:
    @pytest.fixture
    def path(self):
        return "https://www.example.com/path/to/file"

    @pytest.fixture
    def any_other_argument(self):
        return "fakeargument"

    @pytest.fixture
    def gcs_pandas(self):
        return GCSPandas()

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
        gcs_pandas,
    ):
        data_frame = mocker.create_autospec(pd.DataFrame)
        mocker.patch("pandas.read_parquet", return_value=data_frame)

        result = gcs_pandas.read_parquet(path, any_other_argument)

        pd.read_parquet.assert_called_once_with(
            path, any_other_argument, filesystem=gcs_filesystem
        )

        assert result == data_frame

    def test_read_csv(
        self,
        mocker,
        gcs_filesystem,
        gcs_filesystem_setup,
        gcs_pandas,
        path,
        any_other_argument,
    ):
        file = io.StringIO("fakefile")
        data_frame = mocker.create_autospec(pd.DataFrame)
        mocker.patch("pandas.read_csv", return_value=data_frame)
        gcs_filesystem.open.return_value = file

        result = gcs_pandas.read_csv(path, anything=any_other_argument)

        gcs_filesystem.open.assert_called_once_with(path)
        pd.read_csv.assert_called_once_with(file, anything=any_other_argument)

        assert result == data_frame

    def test_read_excel(
        self,
        mocker,
        gcs_filesystem,
        gcs_filesystem_setup,
        gcs_pandas,
        path,
        any_other_argument,
    ):
        file = io.StringIO("fakefile")
        data_frame = mocker.create_autospec(pd.DataFrame)
        mocker.patch("pandas.read_excel", return_value=data_frame)
        gcs_filesystem.open.return_value = file

        result = gcs_pandas.read_excel(path, anything=any_other_argument)

        gcs_filesystem.open.assert_called_once_with(path)
        pd.read_excel.assert_called_once_with(file, anything=any_other_argument)

        assert result == data_frame

    def test_data_frame_to_parquet(
        self,
        mocker,
        path,
        any_other_argument,
        gcs_filesystem,
        gcs_filesystem_setup,
        gcs_pandas,
    ):
        data_frame = mocker.create_autospec(pd.DataFrame)

        gcs_pandas.data_frame_to_parquet(data_frame, path, anything=any_other_argument)

        data_frame.to_parquet.assert_called_once_with(
            path, filesystem=gcs_filesystem, anything=any_other_argument
        )
