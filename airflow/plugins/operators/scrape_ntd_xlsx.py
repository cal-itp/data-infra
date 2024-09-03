"""
This script can be executed manually to scrape a given
NTD data product for a specific year. In the future,
we can trivially turn this into an Airflow operator
and capture NTD data on a recurring basis. The main
feature we should add is getting the actual file URL
from the data set page. For example, the 2021 agency
database page is https://www.transit.dot.gov/ntd/data-product/2021-annual-database-agency-information
but the actual file is https://www.transit.dot.gov/sites/fta.dot.gov/files/2022-10/2021%20Agency%20Information.xlsx
which is linked in the HTML page.

Datasets:
https://www.transit.dot.gov/ntd/data-product/2021-annual-database-agency-information
Contains basic contact and agency information for each NTD reporter.

https://www.transit.dot.gov/ntd/data-product/2022-annual-database-service
Contains operating statistics reported by mode and type of service. Categorized by vehicles operated and vehicles available in maximum service by day and time period.

https://www.transit.dot.gov/ntd/data-product/monthly-module-adjusted-data-release
Monthly ridership

When testing, add these lines and comment one out in your bash_profile.
export CALITP_BUCKET__NTD_DATA_PRODUCTS=gs://calitp-ntd-data-products
export CALITP_BUCKET__NTD_DATA_PRODUCTS=gs://test-calitp-ntd-data-products

Sample Commands:
poetry install
then
poetry run python scrape_ntd.py annual-database-agency-information 2021 https://www.transit.dot.gov/sites/fta.dot.gov/files/2022-10/2021%20Agency%20Information.xlsx
poetry run python scrape_ntd.py monthly-ridership-with-adjustments 2024 https://www.transit.dot.gov/sites/fta.dot.gov/files/2024-04/February%202024%20Complete%20Monthly%20Ridership%20%28with%20adjustments%20and%20estimates%29_240402_0.xlsx
poetry run python scrape_ntd.py annual-database-service 2022 https://www.transit.dot.gov/sites/fta.dot.gov/files/2024-04/2022%20Service.xlsx
"""

import gzip
import logging
import os
from typing import Optional  # , List, ClassVar

import humanize
import pandas as pd  # type: ignore
import pendulum
import requests
import typer
from calitp_data_infra.storage import (  # type: ignore; PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)
from pydantic import BaseModel, HttpUrl, parse_obj_as

from airflow.models import BaseOperator  # type: ignore

# CALITP_BUCKET__NTD_DATA_PRODUCTS = os.environ["CALITP_BUCKET__NTD_DATA_PRODUCTS"]


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


class NtdDataProductXLSXExtract(BaseModel):
    # bucket: ClassVar[str] = CALITP_BUCKET__NTD_DATA_PRODUCTS
    # table: str
    # partition_names: ClassVar[List[str]] = ["dt", "ts", "year"]
    year: int
    product_short: str
    # reinstate
    # table_name: str
    file_url: HttpUrl
    raw_data: Optional[bytes]
    clean_data: Optional[bytes]

    logger: Optional[logging.Logger]
    extract_time: Optional[pendulum.DateTime]

    logger = write_to_log("load_ntd_xlsx_output.log")
    extract_time = pendulum.now()

    # reinstate? probably not
    # @property
    # def table_name(self) -> str:
    #     return self.product

    # @property
    # def dt(self) -> pendulum.Date:
    #     return self.ts.date()

    # pydantic doesn't know dataframe type
    # see https://stackoverflow.com/a/69200069
    class Config:
        arbitrary_types_allowed = True

    def fetch_from_ntd_xlsx(self):
        """ """

        self.logger.info(
            f"Downloading NTD data for {self.year} / {self.product_short}."
        )

        validated_url = parse_obj_as(HttpUrl, self.file_url)
        typer.secho(f"reading file from url {validated_url}", fg=typer.colors.MAGENTA)

        # start = pendulum.now(tz="Etc/UTC")

        # this bytes object needs to be handled !!!!
        # !!!!!!
        excel_content = requests.get(validated_url).content

        if excel_content is None or len(excel_content) == 0:
            self.logger.info(
                f"There is no data to download for {self.year} / {self.product_short}. Ending pipeline."
            )
            pass
        else:
            self.raw_data = excel_content
            # self.data = response

            self.logger.info(
                f"Downloaded {self.product_short} data for {self.year} with {len(self.raw_data)} rows!"
            )

        return self.raw_data

    def make_raw_hive_path(self, product_short: str, raw_bucket: str):
        if not self.extract_time:
            raise ValueError(
                "An extract time must be set before a hive path can be generated."
            )
        return os.path.join(
            raw_bucket,
            f"{self.product_short}_{self.year}",
            f"year={self.extract_time.format('YYYY')}",
            f"dt={self.extract_time.to_date_string()}",
            f"ts={self.extract_time.to_iso8601_string()}",
            f"{self.product_short}_{self.year}.jsonl.gz",
        )

    def save_raw_to_gcs(self, fs, raw_bucket):
        """ """
        raw_hive_path = self.make_raw_hive_path(self.product_short, raw_bucket)
        self.logger.info(f"Uploading to GCS at {raw_hive_path}")

        if self.raw_data is None or (len(self.raw_data) == 0):
            self.logger.info(
                f"There is no raw data for {self.year} / {self.product_short}, not saving anything. Pipeline exiting."
            )
            pass
        else:
            typer.secho(
                f"saving {humanize.naturalsize(len({self.raw_data}))} bytes to {raw_hive_path}"
            )

            fs.pipe(raw_hive_path, gzip.compress(self.raw_data))  # .encode()

            # self.excel_extract.save_content(fs=get_fs(), content=self.excel_content)

            # df_dict = pd.read_excel(self.excel_content, sheet_name=None, engine="openpyxl")

        return raw_hive_path

    def clean_xlxs(self, df_dict):
        df_dict = pd.read_excel(self.raw_data, sheet_name=None, engine="openpyxl")

        # Rename all columns in dictonary, then fix the key(tab) name of the dictionary
        for key, df in df_dict.items():
            df = df.rename(make_name_bq_safe, axis="columns")
            typer.secho(
                f"read {df.shape[0]} rows and {df.shape[1]} columns",
                fg=typer.colors.MAGENTA,
            )

            self.gzipped_content = gzip.compress(
                df.to_json(orient="records", lines=True).encode()
            )

            # reinstate
            # self.table_name = ""
            # if len(df_dict.keys()) > 1:
            #     self.table_name = "/" + make_name_bq_safe(key)

    def make_clean_hive_path(self, product_short: str, clean_bucket: str):
        if not self.extract_time:
            raise ValueError(
                "An extract time must be set before a hive path can be generated."
            )
        return os.path.join(
            clean_bucket,
            f"{self.product_short}_{self.year}",
            # f"{self.product_short}_{self.table_name}_{self.year}",
            f"year={self.extract_time.format('YYYY')}",
            f"dt={self.extract_time.to_date_string()}",
            f"ts={self.extract_time.to_iso8601_string()}",
            f"{self.product_short}_{self.year}.json.gz",
            # f"{self.product_short}_{self.table_name}_{self.year}.json.gz",
        )

    def save_clean_to_gcs(self, fs, clean_bucket):
        """ """
        self.clean_hive_path = self.make_clean_hive_path(
            self.product_short, clean_bucket
        )
        self.logger.info(f"Uploading to GCS at {self.clean_hive_path}")

        if self.clean_data is None or (len(self.clean_data) == 0):
            self.logger.info(
                f"There is no clean data for {self.year} / {self.product_short}, not saving anything. Pipeline exiting."
            )
            pass
        else:
            # typer.secho(
            #     f"saving {humanize.naturalsize(len(self.excel_content))} bytes to {self.excel_extract.path}"
            # )

            typer.secho(
                f"saving {humanize.naturalsize(len(self.gzipped_content))} bytes to {self.clean_hive_path}"
            )

            fs.pipe(self.clean_hive_path, self.gzipped_content)  # .encode()

            # fs.pipe(clean_hive_path, gzip.compress(self.clean_data))  # .encode()

            # self.clean_extract.save_content(fs=get_fs(), content=gzipped_content)

        return self.clean_hive_path


class NtdDataProductXLSXOperator(BaseOperator):
    # template_fields = ("bucket",)

    def __init__(
        self,
        raw_bucket: str,
        clean_bucket: str,
        product_short: str,
        # reinstate
        # table_name: str,
        year: int,
        file_url: str,
        **kwargs,
    ):
        self.raw_bucket = raw_bucket
        self.clean_bucket = clean_bucket

        # Save initial excel files to the bucket as "raw"
        self.raw_extract = NtdDataProductXLSXExtract(
            product_short=product_short,
            # table_name=table_name + "_raw",
            year=year,
            file_url=file_url,
            # filename=f"{product_short}_raw.xlsx",
        )

        self.clean_extract = NtdDataProductXLSXExtract(
            product_short=product_short,
            # table_name=table_name,
            year=year,
            file_url=file_url,
            # filename=f"{product_short}.jsonl.gz",
        )
        super().__init__(**kwargs)

    def execute(self, **kwargs):
        fs = get_fs()

        fetched_data = self.raw_extract.fetch_from_ntd_xlsx()

        # reinstate once we figure out what the deal is with the bytes object
        # fetched_data.save_raw_to_gcs(fs, self.raw_bucket)

        self.clean_extract = fetched_data.clean_xlxs()

        self.clean_extract.save_clean_to_gcs(fs, self.clean_bucket)
