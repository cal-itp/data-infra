"""Module for exporting data from Amplitude and adding to the data warehouse"""
import os
import gzip
import zipfile
from io import BytesIO, StringIO
from datetime import timedelta

import calitp
import requests
import pandas as pd

from airflow.models import BaseOperator

DATE_FORMAT = "%Y%m%dT%H"


def amplitude_to_df(
    start: str,
    end: str,
    api_key: str = None,
    secret_key: str = None,
    api_key_env: str = None,
    secret_key_env: str = None,
):
    """
    Export zipped JSON data from Amplitude API and returns as a pandas dataframe.

    Args:
        start: Start date as a string, first hour included in data series, formatted
            YYYYMMDDTHH (e.g. '20150201T05').
        end: End date as a string, same format as start.
        api_key: API key from Amplitude API.
        secret_key: Secret key from Amplitude API.
        api_key_env: Name of environment variable containing API key from Amplitude API.
        secret_key_env: Name of environment variable containing secret key from Amplitude API.

    Returns:
        A pandas dataframe which has all the events within the date range.

    Raises:
        ValueError: neither 'api_key' nor 'api_key_env' was provided, and/or neither
            'secret_key' nor 'secret_key_env' was provided
        KeyError: 'api_key_env'/'secret_key_env' were provided, but the environment variables
            are not defined
    """

    url = "https://amplitude.com/api/2/export"
    params = {"start": start, "end": end}

    if not any([api_key, api_key_env]):
        raise ValueError("api_key or api_key_env is required.")
    if not any([secret_key, secret_key_env]):
        raise ValueError("secret_key or secret_key_env is required.")

    api_key = api_key or os.environ[api_key_env]
    secret_key = secret_key or os.environ[secret_key_env]

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
    An operator that will download data from Amplitude and upload the
    resulting flattened JSON to GCS.
    """

    def __init__(self, app_name, api_key_env, secret_key_env, **kwargs):
        self.app_name = app_name
        self.api_key_env = api_key_env
        self.secret_key_env = secret_key_env

        super().__init__(**kwargs)

    def execute(self, context):
        # use the DAG's logical date as the data interval start,
        # and ensure the 'start' hour is 0 no matter what the 'schedule_interval' is.
        start_datetime = context.get("execution_date").set(hour=0)

        # add 23 hours to the start date to make the total range equal to 24 hours.
        # (the 'end' parameter is inclusive: https://developers.amplitude.com/docs/export-api#export-api-parameters)
        start = start_datetime.strftime(DATE_FORMAT)
        end = (start_datetime + timedelta(hours=23)).strftime(DATE_FORMAT)

        events_df = amplitude_to_df(
            start, end, api_key_env=self.api_key_env, secret_key_env=self.secret_key_env
        )

        events_jsonl = events_df.to_json(orient="records", lines=True)
        gcs_file_path = f"amplitude/{self.app_name}/{start}-{end}.jsonl"

        # if a file already exists at `gcs_file_path`, GCS will overwrite the existing file
        calitp.save_to_gcfs(events_jsonl.encode(), gcs_file_path, use_pipe=True)
