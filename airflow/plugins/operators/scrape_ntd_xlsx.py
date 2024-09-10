import gzip

# import os
from io import BytesIO
from typing import ClassVar, List

import pandas as pd  # type: ignore
import pendulum
import requests
import typer
from calitp_data_infra.storage import (  # type: ignore
    PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)
from pydantic import HttpUrl, parse_obj_as

from airflow.models import BaseOperator  # type: ignore

# Restore for prod
# RAW_XLSX_BUCKET = os.environ["RAW_XLSX_BUCKET"]
# CLEAN_XLSX_BUCKET = os.environ["CLEAN_XLSX_BUCKET"]

RAW_XLSX_BUCKET = "gs://calitp-ntd-xlsx-products-raw"
CLEAN_XLSX_BUCKET = "gs://calitp-ntd-xlsx-products-clean"


class NtdDataProductXLSXExtractRaw(PartitionedGCSArtifact):
    bucket: ClassVar[str] = RAW_XLSX_BUCKET
    year: str
    product: str
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    file_url: HttpUrl
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]

    @property
    def table(self) -> str:
        return self.product

    class Config:
        arbitrary_types_allowed = True

    def fetch_from_ntd_xlsx(self, file_url):
        validated_url = parse_obj_as(HttpUrl, file_url)

        typer.secho(f"reading file from url {validated_url}", fg=typer.colors.MAGENTA)

        """
        From here:
        need to figure out logging, replace secho, add more for the requests
        need to figure out if moving to one class is possible
        need to finalize naming conventions
        need to do all of this for API
        """

        try:
            excel_content = requests.get(validated_url).content

            if excel_content is None or len(excel_content) == 0:
                typer.secho(
                    f"There is no data to download for {self.year} / {self.product}. Ending pipeline.",
                    fg=typer.colors.MAGENTA,
                )
                pass
            else:
                typer.secho(
                    f"Downloaded {self.product} data for {self.year} with {len(excel_content)} rows!",
                    fg=typer.colors.MAGENTA,
                )

                return excel_content

        except requests.exceptions.RequestException as e:
            # need to figure out logging quick
            print(f"An error occurred: {e}")


class NtdDataProductXLSXExtractClean(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CLEAN_XLSX_BUCKET
    year: str
    product: str
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]

    @property
    def table(self) -> str:
        return self.product

    @property
    def filename(self) -> str:
        return self.table

    class Config:
        arbitrary_types_allowed = True


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

        typer.secho(
            f"file url is {self.xlsx_file_url} and file type is {type(self.xlsx_file_url)}",
            fg=typer.colors.MAGENTA,
        )

        # Save initial excel files to the bucket as "raw"
        self.raw_excel_extract = NtdDataProductXLSXExtractRaw(
            year=year,
            product=product + "_raw",
            file_url=self.xlsx_file_url,
            filename=f"{year}__{product}_raw.xlsx",
        )

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        excel_content = self.raw_excel_extract.fetch_from_ntd_xlsx(
            self.raw_excel_extract.file_url
        )

        self.raw_excel_extract.save_content(fs=get_fs(), content=excel_content)

        excel_data = BytesIO(excel_content)
        df_dict = pd.read_excel(excel_data, sheet_name=None, engine="openpyxl")

        for key, df in df_dict.items():
            df = df.rename(make_name_bq_safe, axis="columns")
            typer.secho(
                f"read {df.shape[0]} rows and {df.shape[1]} columns",
                fg=typer.colors.MAGENTA,
            )

            self.clean_gzipped_content = gzip.compress(
                df.to_json(orient="records", lines=True).encode()
            )

            tab_name = ""

            tab_name = make_name_bq_safe(key)

            self.clean_excel_extract = NtdDataProductXLSXExtractClean(
                year=self.year,
                product=self.product + "/" + tab_name,
                filename=f"{self.year}__{self.product}__{tab_name}.jsonl.gz",
            )

            self.clean_excel_extract.save_content(
                fs=get_fs(), content=self.clean_gzipped_content
            )
