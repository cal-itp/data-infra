import csv
import gzip
import logging
import os
import re
from typing import Optional

import pendulum
import requests
from calitp_data_infra.storage import get_fs  # type: ignore
from pydantic import BaseModel, Json

from airflow.models import BaseOperator  # type: ignore

# CALITP_BUCKET__NTD_DATA_PRODUCTS = os.environ["CALITP_BUCKET__NTD_DATA_PRODUCTS"]

filename = "./data/ntd_endpoints.csv"


def write_to_log(logfilename):
    """
    Creates a logger object that outputs to a log file, to the filename specified,
    and also streams to console.
    """
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter(
        "%(asctime)s:%(levelname)s: %(message)s", datefmt="%y-%m-%d %H:%M:%S"
    )
    file_handler = logging.FileHandler(logfilename)
    file_handler.setFormatter(formatter)
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)

    if not logger.hasHandlers():
        logger.addHandler(file_handler)
        logger.addHandler(stream_handler)

    return logger


class NtdDataProductAPIExtract(BaseModel):
    endpoint_id: str
    product: str
    year: str
    data: Json
    logger: Optional[logging.Logger]
    extract_time: Optional[pendulum.DateTime]

    # bucket = CALITP_BUCKET__NTD_DATA_PRODUCTS
    logger = write_to_log("load_ntd_apidata_output.log")
    extract_time = pendulum.now()

    # pydantic doesn't know dataframe type
    # see https://stackoverflow.com/a/69200069
    class Config:
        arbitrary_types_allowed = True

    def fetch_from_ntd_api(self):
        """Restore comments"""

        self.logger.info(f"Downloading NTD data for {self.year} / {self.product}.")

        url = (
            "https://data.transportation.gov/resource/"
            + self.endpoint_id
            + ".json"
            + "?$limit=5000000"
        )

        response = requests.get(url).content

        if response is None or len(response) == 0:
            self.logger.info(
                f"There is no data to download for {self.year} / {self.product}. Ending pipeline."
            )
            pass
        else:
            self.data = response
            self.logger.info(
                f"Downloaded {self.product} data for {self.year} with {len(self.data)} rows!"
            )

    def make_hive_path(self, product: str, bucket: str):
        if not self.extract_time:
            raise ValueError(
                "An extract time must be set before a hive path can be generated."
            )
        return os.path.join(
            bucket,
            f"{self.product}_{self.year}",
            f"year={self.extract_time.format('YYYY')}",
            f"dt={self.extract_time.to_date_string()}",
            f"ts={self.extract_time.to_iso8601_string()}",
            f"{self.product}_{self.year}.jsonl.gz",
        )

    def save_to_gcs(self, fs, bucket):
        hive_path = self.make_hive_path(self.product, bucket)
        self.logger.info(f"Uploading to GCS at {hive_path}")
        if (self.data is None) or (len(self.data) == 0):
            self.logger.info(
                f"There is no data for {self.year} / {self.product}, not saving anything. Pipeline exiting."
            )
            pass
        else:
            fs.pipe(hive_path, gzip.compress(self.data))  # .encode()),
        return hive_path


class NtdDataProductAPIOperator(BaseOperator):
    template_fields = ("bucket",)

    def __init__(
        self,
        bucket,
        **kwargs,
    ):
        """An operator that downloads all data from a NTD API
            and saves it as one JSON file hive-partitioned by date in Google Cloud
            Storage (GCS). DELETE:(Each org's data will be in 1 row, and for each separate table in the API,
            a nested column will hold all of it's data.)

        Args:
            bucket (str): GCS bucket where the scraped NTD data will be saved.
        """
        self.bucket = bucket

        if self.bucket and os.environ["AIRFLOW_ENV"] == "development":
            self.bucket = re.sub(r"gs://([\w-]+)", r"gs://test-\1", self.bucket)

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        with open(filename, "r") as csvfile:
            ntd_endpoints = csv.reader(csvfile)
            for row in ntd_endpoints:
                fs = get_fs()

                # Instantiating an instance of the NtdDataProductAPIExtract()
                self.extract = NtdDataProductAPIExtract(
                    endpoint_id=row[4], product=row[2], year=row[0]
                )

                self.extract.fetch_from_ntd_api()
                # inserts into xcoms
                self.extract.save_to_gcs(fs, self.bucket)
