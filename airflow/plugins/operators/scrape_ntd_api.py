# import os
import gzip
import logging
from typing import ClassVar, List  # , Optional

import pandas as pd  # type: ignore
import pendulum
import requests

# import typer
from calitp_data_infra.storage import PartitionedGCSArtifact, get_fs  # type: ignore
from pydantic import HttpUrl, parse_obj_as

from airflow.models import BaseOperator  # type: ignore

# Restore for prod
# API_BUCKET = os.environ["CALITP_BUCKET__NTD_API_DATA_PRODUCTS"]

API_BUCKET = "gs://calitp-ntd-api-products"


class NtdDataProductAPIExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str]
    year: str
    product: str
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    root_url: str
    endpoint_id: str
    file_format: str
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]

    @property
    def table(self) -> str:
        return self.product

    @property
    def filename(self) -> str:
        return self.table

    class Config:
        arbitrary_types_allowed = True

    def fetch_from_ntd_api(self):
        """ """

        logging.info(f"Downloading NTD data for {self.year} / {self.product}.")

        try:
            url = (
                self.root_url + self.endpoint_id + self.file_format + "?$limit=5000000"
            )

            validated_url = parse_obj_as(HttpUrl, url)

            response = requests.get(validated_url).content

            if response is None or len(response) == 0:
                logging.info(
                    f"There is no data to download for {self.year} / {self.product}. Ending pipeline."
                )

                pass
            else:
                logging.info(
                    f"Downloaded {self.product} data for {self.year} with {len(response)} rows!"
                )

                return response

        except requests.exceptions.RequestException as e:
            logging.info(f"An error occurred: {e}")

            raise


class CSVExtract(NtdDataProductAPIExtract):
    bucket = API_BUCKET


class NtdDataProductAPIOperator(BaseOperator):
    template_fields = ("year", "product", "root_url", "endpoint_id", "file_format")

    def __init__(
        self,
        year,
        product,
        root_url,
        endpoint_id,
        file_format,
        **kwargs,
    ):
        self.year = year
        self.product = product
        self.root_url = root_url
        self.endpoint_id = endpoint_id
        self.file_format = file_format
        """An operator that downloads all data from a NTD API
            and saves it as one CSV file hive-partitioned by date in Google Cloud
        """

        # Save CSV files to the bucket
        self.extract = CSVExtract(
            year=self.year,
            product=self.product + "/" + self.year,
            root_url=self.root_url,
            endpoint_id=self.endpoint_id,
            file_format=self.file_format,
            filename=f"{self.year}__{self.product}.jsonl.gz",
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        api_content = self.extract.fetch_from_ntd_api()

        decode_api_content = api_content.decode("utf-8")

        df = pd.read_json(decode_api_content)

        self.gzipped_content = gzip.compress(
            df.to_json(orient="records", lines=True).encode()
        )

        self.extract.save_content(fs=get_fs(), content=self.gzipped_content)
