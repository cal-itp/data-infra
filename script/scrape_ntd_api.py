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

import csv
import gzip
import os
from typing import ClassVar, List

import humanize
import pendulum
import requests
import typer
from calitp_data_infra.storage import PartitionedGCSArtifact, get_fs  # type: ignore

CALITP_BUCKET__NTD_DATA_PRODUCTS = os.environ["CALITP_BUCKET__NTD_DATA_PRODUCTS"]


class NtdDataProductExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__NTD_DATA_PRODUCTS
    # table: str
    partition_names: ClassVar[List[str]] = ["dt", "ts", "year"]
    product: str
    ts: pendulum.DateTime
    year: int
    api_endpoint: str

    @property
    def table(self) -> str:
        return self.product

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()


def main(
    # product: str,
    # year: int,
    # api_endpoint: str,
):
    filename = "ntd_endpoints.csv"

    with open(filename, "r") as csvfile:
        ntd_endpoints = csv.reader(csvfile)
        for row in ntd_endpoints:
            # print(row[2])

            # ntd_endpoints = pd.read_csv('ntd_endpoints.csv')
            # for endpoint in ntd_endpoints:
            #     print(endpoint)

            # print(ntd_endpoints.full_name)
            # for endpoint in ntd_endpoints:

            # print(endpoint)
            typer.secho(
                f"reading file from api_endpoint: {row[4]}", fg=typer.colors.MAGENTA
            )
            start = pendulum.now(tz="Etc/UTC")
            api_endpoint = (
                "https://data.transportation.gov/resource/"
                + row[4]
                + ".json"
                + "?$limit=5000000"
            )

            api_content = requests.get(api_endpoint).content

            # print(api_content)
            # Save initial json files to the bucket as "raw"
            api_extract = NtdDataProductExtract(
                product=row[2],
                ts=start,
                year=row[0],
                api_endpoint=row[4],
                filename=f"{row[2]}.jsonl.gz",
            )

            gzipped_content = gzip.compress(api_content)  # .encode()

            typer.secho(
                f"saving {humanize.naturalsize(len(gzipped_content))} bytes to {api_extract.path}"
            )

            api_extract.save_content(fs=get_fs(), content=gzipped_content)


if __name__ == "__main__":
    typer.run(main)
