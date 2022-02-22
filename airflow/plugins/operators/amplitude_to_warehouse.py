"""Module for exporting data from Amplitude and adding to the data warehouse"""
import os
import functools
import gzip
import zipfile
from datetime import datetime, timedelta
from io import BytesIO, StringIO

import requests
import pandas as pd

from airflow.models import BaseOperator

DATE_FORMAT = "%Y%m%dT%H"


def amplitude_to_df(
    start: str,
    end: str,
    api_key: str = os.environ.get("CALITP_AMPLITUDE_BENEFITS_API_KEY"),
    secret_key: str = os.environ.get("CALITP_AMPLITUDE_BENEFITS_SECRET_KEY"),
):
    """Export data from Amplitude into a dataframe."""
    url = "https://amplitude.com/api/2/export"
    params = {"start": start, "end": end}

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


class AmplitudeToWarehouseOperator(BaseOperator):
    """
    An operator that will download data from Amplitude and load it into
    the CalITP data warehouse.
    """

    def __init__(self, **kwargs):
        super().__init__(self, **kwargs)

    def execute(self, context):
        pass
