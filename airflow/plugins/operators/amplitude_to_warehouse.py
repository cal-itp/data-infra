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


def handle_errors(func):
    """Decorator to handle retrying if errors are returned from Amplitude Export API."""

    @functools.wraps(func)
    def wrapper_handle_errors(*args, **kwargs):
        # Set up the stack of date ranges
        start = kwargs["start"] if "start" in kwargs else args[0]
        end = kwargs["end"] if "end" in kwargs else args[1]
        date_range_stack = [(start, end)]

        # Build keys dict
        keys = {}
        api_key = kwargs["api_key"] if "api_key" in kwargs else args[2]
        if api_key:
            keys["api_key"] = api_key
        secret_key = kwargs["secret_key"] if "secret_key" in kwargs else args[3]
        if secret_key:
            keys["secret_key"] = secret_key

        df_list = []

        # Main loop
        while date_range_stack:
            date_range = date_range_stack.pop()

            try:
                start = date_range[0]
                end = date_range[1]

                df = func(start, end, **keys)
            except requests.HTTPError as err:
                if err.response.status_code in {400, 504}:  # date range was too large
                    add_date_ranges_to_retry(date_range, date_range_stack)
                else:
                    raise err
            else:
                df_list.append(df)

        return pd.concat(df_list) if df_list else pd.DataFrame()

    return wrapper_handle_errors


def add_date_ranges_to_retry(
    failed_date_range, date_range_stack, threshold_for_dropping=timedelta(days=1)
):
    """Splits the failed date range into two smaller date ranges, and adds to the stack.
    If the date range has a delta smaller than the value of 'threshold_for_dropping',
    the date range will be dropped.
    """
    start = failed_date_range[0]
    end = failed_date_range[1]

    start_datetime = datetime.strptime(start, DATE_FORMAT)
    end_datetime = datetime.strptime(end, DATE_FORMAT)

    difference = end_datetime - start_datetime

    if difference > threshold_for_dropping:
        midpoint_datetime = end_datetime - (difference / 2)
        midpoint_left = datetime.strftime(midpoint_datetime, DATE_FORMAT)
        midpoint_right = datetime.strftime(
            midpoint_datetime + timedelta(hours=1), DATE_FORMAT
        )

        # push (midpoint + 1, end) into stack
        date_range_stack.append((midpoint_right, end))
        # push (start, midpoint) into stack
        date_range_stack.append((start, midpoint_left))


@handle_errors
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
