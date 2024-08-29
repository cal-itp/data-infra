# import csv
import gzip

# import json
import logging
import os

# import re
from typing import Optional

import pendulum
import requests
from calitp_data_infra.storage import get_fs  # type: ignore
from pydantic import BaseModel  # , Json

from airflow.models import BaseOperator  # type: ignore


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
    year: str
    product_short: str
    root_url: str
    endpoint_id: str
    file_format: str
    data: Optional[bytes]

    logger: Optional[logging.Logger]
    extract_time: Optional[pendulum.DateTime]

    logger = write_to_log("load_ntd_api_output.log")
    extract_time = pendulum.now()

    # pydantic doesn't know dataframe type
    # see https://stackoverflow.com/a/69200069
    class Config:
        arbitrary_types_allowed = True

    def fetch_from_ntd_api(self):
        """ """

        self.logger.info(
            f"Downloading NTD data for {self.year} / {self.product_short}."
        )

        url = self.root_url + self.endpoint_id + self.file_format + "?$limit=5000000"
        response = requests.get(url).content
        # decoded_response = response.decode("utf-8")
        # load_response_json = json.loads(decode_respose)
        # json_filepath = f"{self.endpoint_id}_data.jsonl"

        if response is None or len(response) == 0:
            self.logger.info(
                f"There is no data to download for {self.year} / {self.product_short}. Ending pipeline."
            )
            pass
        else:
            # self.data = decoded_response
            self.data = response

            self.logger.info(
                f"Downloaded {self.product_short} data for {self.year} with {len(self.data)} rows!"
            )

    def make_hive_path(self, product_short: str, bucket: str):
        if not self.extract_time:
            raise ValueError(
                "An extract time must be set before a hive path can be generated."
            )
        return os.path.join(
            bucket,
            f"{self.product_short}_{self.year}",
            f"year={self.extract_time.format('YYYY')}",
            f"dt={self.extract_time.to_date_string()}",
            f"ts={self.extract_time.to_iso8601_string()}",
            f"{self.product_short}_{self.year}.csv.gz",
            # f"{self.product_short}_{self.year}_raw.jsonl.gz",
        )

    def save_to_gcs(self, fs, bucket):
        """ """
        hive_path = self.make_hive_path(self.product_short, bucket)
        self.logger.info(f"Uploading to GCS at {hive_path}")

        if self.data is None:  # or (len(self.data) == 0):
            self.logger.info(
                f"There is no data for {self.year} / {self.product_short}, not saving anything. Pipeline exiting."
            )
            pass
        else:
            fs.pipe(hive_path, gzip.compress(self.data))  # .encode()
        return hive_path


class NtdDataProductAPIOperator(BaseOperator):
    template_fields = ("bucket",)

    def __init__(
        self,
        bucket,
        year,
        product_short,
        root_url,
        endpoint_id,
        file_format,
        **kwargs,
    ):
        self.bucket = bucket
        """An operator that downloads all data from a NTD API
            and saves it as one JSON file hive-partitioned by date in Google Cloud
            Storage (GCS). DELETE:(Each org's data will be in 1 row, and for each separate table in the API,
            a nested column will hold all of it's data.)

        Args:
            bucket (str): GCS bucket where the scraped NTD data will be saved.
        """

        # if self.bucket and os.environ["AIRFLOW_ENV"] == "development":
        #     self.bucket = re.sub(r"gs://([\w-]+)", r"gs://test-\1", self.bucket)

        # Instantiating an instance of the NtdDataProductAPIExtract()
        self.extract = NtdDataProductAPIExtract(
            year=year,
            product_short=product_short,
            root_url=root_url,
            endpoint_id=endpoint_id,
            file_format=file_format,
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        fs = get_fs()

        self.extract.fetch_from_ntd_api()
        # inserts into xcoms
        return self.extract.save_to_gcs(fs, self.bucket)
