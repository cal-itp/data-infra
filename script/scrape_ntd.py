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

Sample Command:
`python scrape_ntd.py annual-database-agency-information 2021 https://www.transit.dot.gov/sites/fta.dot.gov/files/2022-10/2021%20Agency%20Information.xlsx`
"""
import gzip
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

# CALITP_BUCKET__NTD_DATA_PRODUCTS = os.environ["CALITP_BUCKET__NTD_DATA_PRODUCTS"]
# bucket: gs://calitp-ntd-data-products
CALITP_BUCKET__NTD_DATA_PRODUCTS = "gs://test-calitp-ntd-data-products"


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
    df_dict = pd.read_excel(
        requests.get(validated_url).content, sheet_name=None, engine="openpyxl"
    )

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
