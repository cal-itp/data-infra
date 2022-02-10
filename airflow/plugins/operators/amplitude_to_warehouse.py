"""Module for exporting data from Amplitude and adding to the data warehouse"""
import os
import gzip
import zipfile
from io import BytesIO

import requests
import pandas as pd

from airflow.models import BaseOperator


def amplitude_to_df(start, end, api_key=None, secret_key=None):
    """Export data from Amplitude into a dataframe."""
    api_key = (
        os.environ["CALITP_AMPLITUDE_BENEFITS_API_KEY"] if not api_key else api_key
    )
    secret_key = (
        os.environ("CALITP_AMPLITUDE_BENEFITS_SECRET_KEY")
        if not secret_key
        else secret_key
    )

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
                temp_df = pd.read_json(events, lines=True)
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
