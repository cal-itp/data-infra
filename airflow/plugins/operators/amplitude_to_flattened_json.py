"""Module for exporting data from Amplitude and adding to the data warehouse"""
import os
import gzip
import zipfile
from io import BytesIO, StringIO

import requests
import pandas as pd

from airflow.models import BaseOperator

DATE_FORMAT = "%Y%m%dT%H"


def amplitude_to_df(start: str, end: str, api_key: str = None, secret_key: str = None):
    """
    Export zipped JSON data from Amplitude API and returns as a panda dataframe.

    Args:
        start: Start date as a string, first hour included in data series, formatted YYYYMMDDTHH (e.g. '20150201T05').
        end: End date as a string, same format as start.
        api_key: API key from Amplitude API.
        secret_key: Secret key from Amplitude API.

    Returns:
        A panda dataframe which has all the events within the date range.
    """

    url = "https://amplitude.com/api/2/export"
    params = {"start": start, "end": end}
    api_key = api_key or os.environ.get("CALITP_AMPLITUDE_BENEFITS_API_KEY")
    secret_key = secret_key or os.environ.get("CALITP_AMPLITUDE_BENEFITS_SECRET_KEY")

    response = requests.get(url, params=params, auth=(api_key, secret_key), stream=True)

    # raise HTTPError if an error status code was returned
    response.raise_for_status()

    df_list = []
    with zipfile.ZipFile(BytesIO(response.content)) as export:
        for name in export.namelist():
            with export.open(name) as compressed_file:
                events = gzip.decompress(compressed_file.read()).decode()
                temp_df = pd.read_json(StringIO(events), lines=True)
                df_list.append(temp_df)

    return pd.concat(df_list)


class AmplitudeToFlattenedJSONOperator(BaseOperator):
    """
    An operator that will download data from Amplitude and upload the resulting flattened JSON to GCS.
    """

    def __init__(self, **kwargs):
        super().__init__(self, **kwargs)

    def execute(self, context):
        pass
