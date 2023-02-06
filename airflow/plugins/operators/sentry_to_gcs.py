import os
import pandas as pd
import pendulum
import requests

from calitp.auth import get_secret_by_name
from calitp.storage import get_fs, make_name_bq_safe, PartitionedGCSArtifact
from typing import ClassVar, List, Optional

from airflow.models import BaseOperator

BASE_URL = "https://sentry.k8s.calitp.jarv.us/api/0/"
CALITP_BUCKET__SENTRY_LOGS = os.environ["CALITP_BUCKET__SENTRY_LOGS"]


def process_arrays_for_nulls(arr):
    """
    BigQuery doesn't allow arrays that contain null values --
    see: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#array_nulls
    Therefore we need to manually replace nulls with falsy values according
    to the type of data in the array.
    """
    types = set(type(entry) for entry in arr if entry is not None)

    if not types:
        return []
    # use empty string for all non-numeric types
    # may need to expand this over time
    filler = -1 if types <= {int, float} else ""
    return [x if x is not None else filler for x in arr]


def make_arrays_bq_safe(raw_data):
    safe_data = {}
    for k, v in raw_data.items():
        if isinstance(v, dict):
            v = make_arrays_bq_safe(v)
        elif isinstance(v, list):
            v = process_arrays_for_nulls(v)
        safe_data[k] = v
    return safe_data


class SentryExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__SENTRY_LOGS
    table: ClassVar[str] = "events"
    dt: pendulum.Date
    ts: pendulum.DateTime
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    issue_id: int
    data: Optional[bytes]
    extract_ts: Optional[pendulum.DateTime]

    # pydantic doesn't know dataframe type
    # see https://stackoverflow.com/a/69200069
    class Config:
        arbitrary_types_allowed = True

    def iterate_over_sentry_records(self, auth_token):
        """
        Paginate over Sentry API responses for an issue and create a combined list of dicts.
        """
        response_data = []
        next_url = BASE_URL + f"issues/{self.issue_id}/events/"
        headers = {"Authorization": "Bearer " + auth_token}

        while next_url:
            response = requests.get(next_url, headers=headers)
            response_data.extend(response.json())
            if response.links["next"]["results"] == "true":
                next_url = response.links["next"]["url"]
            else:
                next_url = None

        return response_data

    def fetch_and_clean_from_sentry(self, auth_token):
        """
        Download Sentry event records as a DataFrame.
        """

        print(f"Downloading Sentry event data for issue ID {self.issue_id}")
        all_rows = self.iterate_over_sentry_records(auth_token)
        self.extract_ts = pendulum.now()

        raw_df = pd.DataFrame([{**make_arrays_bq_safe(row)} for row in all_rows])

        cleaned_df = raw_df.rename(make_name_bq_safe, axis="columns")

        self.data = cleaned_df.to_json(orient="records", lines=True).encode()

    def save_to_gcs(self, fs):
        self.save_content(fs=fs, content=self.data, exclude={"data"})


class SentryToGCSOperator(BaseOperator):

    template_fields = ("bucket",)

    def __init__(
        self,
        bucket,
        issue_id,
        auth_token=None,
        **kwargs,
    ):
        """
        An operator that downloads data from a specific issue within a Sentry instance
        and saves it as a JSON file hive-partitioned by date and time in Google Cloud
        Storage (GCS).

        Args:
            bucket (str): GCS bucket where the scraped Sentry issue will be saved.
            issue_id (int): The underlying id of the Sentry issue being examined.
            auth_token (str, optional): The auth token to use when downloading from Sentry.
                This can be someone's personal auth token. If not provided, the environment
                variable of `CALITP_SENTRY_AUTH_TOKEN` is used.
        """
        self.ts = pendulum.now()
        self.dt = self.ts.date()
        self.bucket = bucket
        self.extract = SentryExtract(
            issue_id=issue_id, dt=self.dt, ts=self.ts, filename=f"{issue_id}.jsonl.gz"
        )
        self.auth_token = auth_token

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        auth_token = self.auth_token or get_secret_by_name("CALITP_SENTRY_AUTH_TOKEN")
        self.extract.fetch_and_clean_from_sentry(auth_token)
        fs = get_fs()
        # inserts into xcoms
        return self.extract.save_to_gcs(fs=fs)
