import gzip
import logging
from typing import ClassVar, List  # , Optional

import pandas as pd  # type: ignore
import pendulum
import requests
from calitp_data_infra.storage import PartitionedGCSArtifact, get_fs  # type: ignore
from pydantic import HttpUrl, parse_obj_as

from airflow.models import BaseOperator  # type: ignore

API_BUCKET = "gs://calitp-state-geoportal-scrape"
# API_BUCKET = os.environ["CALITP_BUCKET__STATE_GEOPORTAL_DATA_PRODUCTS"]


class StateGeoportalAPIExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str]
    product: str
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    root_url: str
    endpoint_id: str
    query: str
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

    def fetch_from_state_geoportal(self):
        """ """

        logging.info(f"Downloading state geoportal data for {self.product}.")

        try:
            url = self.root_url + self.endpoint_id + self.query + self.file_format

            validated_url = parse_obj_as(HttpUrl, url)

            response = requests.get(validated_url).content

            if response is None or len(response) == 0:
                logging.info(
                    f"There is no data to download for {self.product}. Ending pipeline."
                )

                pass
            else:
                logging.info(
                    f"Downloaded {self.product} data with {len(response)} rows!"
                )

                return response

        except requests.exceptions.RequestException as e:
            logging.info(f"An error occurred: {e}")

            raise


class JSONExtract(StateGeoportalAPIExtract):
    bucket = API_BUCKET


class StateGeoportalAPIOperator(BaseOperator):
    template_fields = ("product", "root_url", "endpoint_id", "query", "file_format")

    def __init__(
        self,
        product,
        root_url,
        endpoint_id,
        query,
        file_format,
        **kwargs,
    ):
        self.product = product
        self.root_url = root_url
        self.endpoint_id = endpoint_id
        self.query = query
        self.file_format = file_format

        """An operator that extracts and saves JSON data from the State Geoportal
            and saves it as one JSONL file, hive-partitioned by date in Google Cloud
        """

        # Save JSONL files to the bucket
        self.extract = JSONExtract(
            product=self.product,
            root_url=self.root_url,
            endpoint_id=self.endpoint_id,
            query=self.query,
            file_format=self.file_format,
            filename=f"{self.product}.jsonl.gz",
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        api_content = self.extract.fetch_from_state_geoportal()

        decode_api_content = api_content.decode("utf-8")

        df = pd.read_json(decode_api_content, lines=True)

        self.gzipped_content = gzip.compress(
            df.to_json(orient="records", lines=True).encode()
        )

        self.extract.save_content(fs=get_fs(), content=self.gzipped_content)
