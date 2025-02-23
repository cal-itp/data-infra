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

https://www.transit.dot.gov/ntd/data-product/monthly-module-adjusted-data-release
Monthly ridership

When testing, add these lines and comment one out in your bash_profile.
export CALITP_BUCKET__NTD_DATA_PRODUCTS=gs://calitp-ntd-data-products
export CALITP_BUCKET__NTD_DATA_PRODUCTS=gs://test-calitp-ntd-data-products

Sample Commands:
poetry install
then
poetry run python scrape_ntd.py annual-database-agency-information 2021 https://www.transit.dot.gov/sites/fta.dot.gov/files/2022-10/2021%20Agency%20Information.xlsx

-- REPLACED by "/airflow/plugins/operators/scrape_ntd_xlsx.py"
-- poetry run python scrape_ntd.py monthly-ridership-with-adjustments 2024 https://www.transit.dot.gov/sites/fta.dot.gov/files/2024-04/February%202024%20Complete%20Monthly%20Ridership%20%28with%20adjustments%20and%20estimates%29_240402_0.xlsx
"""

import gzip
import os
from typing import ClassVar, List

import humanize
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

CALITP_BUCKET__NTD_DATA_PRODUCTS = os.environ["CALITP_BUCKET__NTD_DATA_PRODUCTS"]


class NtdDataProductExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__NTD_DATA_PRODUCTS
    # table: str
    partition_names: ClassVar[List[str]] = ["dt", "ts", "year"]
    product: str
    ts: pendulum.DateTime
    year: int
    file_url: HttpUrl

    @property
    def table(self) -> str:
        return self.product

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()


def main(
    product: str,
    year: int,
    file_url: str,
):
    validated_url = parse_obj_as(HttpUrl, file_url)
    typer.secho(f"reading file from url {validated_url}", fg=typer.colors.MAGENTA)
    start = pendulum.now(tz="Etc/UTC")

    excel_content = requests.get(validated_url).content

    # Save initial excel files to the bucket as "raw"
    excel_extract = NtdDataProductExtract(
        product=product + "_raw",
        ts=start,
        year=year,
        file_url=validated_url,
        filename=f"{product}_raw.xlsx",
    )
    typer.secho(
        f"saving {humanize.naturalsize(len(excel_content))} bytes to {excel_extract.path}"
    )
    excel_extract.save_content(fs=get_fs(), content=excel_content)

    df_dict = pd.read_excel(excel_content, sheet_name=None, engine="openpyxl")

    # Rename all columns in dictonary, then fix the key(tab) name of the dictionary
    for key, df in df_dict.items():
        df = df.rename(make_name_bq_safe, axis="columns")
        typer.secho(
            f"read {df.shape[0]} rows and {df.shape[1]} columns",
            fg=typer.colors.MAGENTA,
        )

        gzipped_content = gzip.compress(
            df.to_json(orient="records", lines=True).encode()
        )

        tab_name = ""
        if len(df_dict.keys()) > 1:
            tab_name = "/" + make_name_bq_safe(key)
        extract = NtdDataProductExtract(
            product=product + tab_name,
            ts=start,
            year=year,
            file_url=validated_url,
            filename=f"{product}.jsonl.gz",
        )
        typer.secho(
            f"saving {humanize.naturalsize(len(gzipped_content))} bytes to {extract.path}"
        )
        extract.save_content(fs=get_fs(), content=gzipped_content)


if __name__ == "__main__":
    typer.run(main)
