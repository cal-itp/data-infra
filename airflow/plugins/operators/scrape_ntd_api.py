import gzip
import logging
import os
from typing import ClassVar, List  # , Optional

import pandas as pd  # type: ignore
import pendulum
import requests
from calitp_data_infra.storage import (  # type: ignore
    PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)
from pydantic import HttpUrl, parse_obj_as

from airflow.exceptions import AirflowException
from airflow.models import BaseOperator  # type: ignore

API_BUCKET = os.environ["CALITP_BUCKET__NTD_API_DATA_PRODUCTS"]


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

            response = requests.get(validated_url)
            response.raise_for_status()  # Raises an HTTPError for bad responses
            response_content = response.content

            if response_content is None or len(response_content) == 0:
                logging.info(
                    f"There is no data to download for {self.year} / {self.product}. Ending pipeline."
                )
                return None

            logging.info(
                f"Downloaded {self.product} data for {self.year} with {len(response_content)} rows!"
            )
            return response_content

        except requests.exceptions.HTTPError as e:
            logging.error(f"HTTP error occurred: {e}")
            raise AirflowException(f"HTTP error in NTD API request: {e}")
        except requests.exceptions.RequestException as e:
            logging.error(f"Request error occurred: {e}")
            raise AirflowException(f"Error in NTD API request: {e}")
        except Exception as e:
            logging.error(f"Unexpected error occurred: {e}")
            raise AirflowException(f"Unexpected error in NTD API request: {e}")


class JSONExtract(NtdDataProductAPIExtract):
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
        """An operator that extracts and saves JSON data from the NTD API
            and saves it as one JSONL file, hive-partitioned by date in Google Cloud
        """

        # Save JSONL files to the bucket
        self.extract = JSONExtract(
            year=self.year,
            product=self.product + "/" + self.year,
            root_url=self.root_url,
            endpoint_id=self.endpoint_id,
            file_format=self.file_format,
            filename=f"{self.year}__{self.product}.jsonl.gz",
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        try:
            api_content = self.extract.fetch_from_ntd_api()
            if api_content is None:
                return None

            decode_api_content = api_content.decode("utf-8")
            df = pd.read_json(decode_api_content)
            df = df.rename(make_name_bq_safe, axis="columns")

            self.gzipped_content = gzip.compress(
                df.to_json(orient="records", lines=True).encode()
            )

            self.extract.save_content(fs=get_fs(), content=self.gzipped_content)

        except ValueError as e:
            logging.error(f"Error parsing JSON data: {e}")
            raise AirflowException(f"Failed to parse JSON data: {e}")
        except Exception as e:
            logging.error(f"Error processing NTD API data: {e}")
            raise AirflowException(f"Failed to process NTD API data: {e}")
