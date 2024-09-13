import gzip

# import os
import logging
from io import BytesIO
from typing import ClassVar, List  # Optional

import pandas as pd  # type: ignore
import pendulum
import requests

# import typer
from calitp_data_infra.storage import (  # type: ignore
    PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)
from pydantic import HttpUrl, parse_obj_as

from airflow.models import BaseOperator  # type: ignore

# Restore for prod
# RAW_XLSX_BUCKET = os.environ["CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"]
# CLEAN_XLSX_BUCKET = os.environ["CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"]

RAW_XLSX_BUCKET = "gs://calitp-ntd-xlsx-products-raw"
CLEAN_XLSX_BUCKET = "gs://calitp-ntd-xlsx-products-clean"


class NtdDataProductXLSXExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str]
    year: str
    product: str
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    file_url: HttpUrl = None
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]

    @property
    def table(self) -> str:
        return self.product

    @property
    def filename(self) -> str:
        return self.table

    class Config:
        arbitrary_types_allowed = True

    def fetch_from_ntd_xlsx(self, file_url):
        validated_url = parse_obj_as(HttpUrl, file_url)

        logging.info(f"reading file from url {validated_url}")

        try:
            excel_content = requests.get(validated_url).content

            if excel_content is None or len(excel_content) == 0:
                logging.info(
                    f"There is no data to download for {self.year} / {self.product}. Ending pipeline."
                )

                pass

            else:
                logging.info(
                    f"Downloaded {self.product} data for {self.year} with {len(excel_content)} rows!"
                )

                return excel_content

        except requests.exceptions.RequestException as e:
            logging.info(f"An error occurred: {e}")

            raise


class RawExtract(NtdDataProductXLSXExtract):
    bucket = RAW_XLSX_BUCKET


class CleanExtract(NtdDataProductXLSXExtract):
    bucket = CLEAN_XLSX_BUCKET


class NtdDataProductXLSXOperator(BaseOperator):
    template_fields = ("year", "product", "xlsx_file_url")

    def __init__(
        self,
        product: str,
        xlsx_file_url,
        year: int,
        **kwargs,
    ):
        self.year = year
        self.product = product
        self.xlsx_file_url = xlsx_file_url

        # Save initial excel files to the raw bucket
        self.raw_excel_extract = RawExtract(
            year=self.year,
            product=self.product + "_raw" + "/" + self.year,
            file_url=self.xlsx_file_url,
            filename=f"{self.year}__{self.product}_raw.xlsx",
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        excel_content = self.raw_excel_extract.fetch_from_ntd_xlsx(
            self.raw_excel_extract.file_url
        )
        logging.info(
            f"file url is {self.xlsx_file_url} and file type is {type(self.xlsx_file_url)}"
        )

        self.raw_excel_extract.save_content(fs=get_fs(), content=excel_content)

        excel_data = BytesIO(excel_content)
        df_dict = pd.read_excel(excel_data, sheet_name=None, engine="openpyxl")

        for key, df in df_dict.items():
            df = df.rename(make_name_bq_safe, axis="columns")

            logging.info(f"read {df.shape[0]} rows and {df.shape[1]} columns")

            self.clean_gzipped_content = gzip.compress(
                df.to_json(orient="records", lines=True).encode()
            )

            tab_name = ""

            tab_name = make_name_bq_safe(key)

            # Save clean gzipped jsonl files to the clean bucket
            self.clean_excel_extract = CleanExtract(
                year=self.year,
                product=self.product + "/" + self.year + "/" + tab_name,
                filename=f"{self.year}__{self.product}__{tab_name}.jsonl.gz",
            )

            self.clean_excel_extract.save_content(
                fs=get_fs(), content=self.clean_gzipped_content
            )
