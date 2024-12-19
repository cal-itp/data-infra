import gzip
import logging
import os
from io import BytesIO
from typing import ClassVar, List  # Optional

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

RAW_XLSX_BUCKET = os.environ["CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"]
CLEAN_XLSX_BUCKET = os.environ["CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"]

# Map product and year combinations to their xcom keys for dynamic url scraping
xcom_keys = {
    (
        "complete_monthly_ridership_with_adjustments_and_estimates",
        "historical",
    ): "ridership_url",
    ("annual_database_agency_information", "2022"): "2022_agency_url",
    ("annual_database_agency_information", "2023"): "2023_agency_url",
    (
        "annual_database_contractual_relationship",
        "2023",
    ): "contractual_relationship_url",
    (
        "operating_and_capital_funding_time_series",
        "historical",
    ): "operating_and_capital_funding_url",
    (
        "service_data_and_operating_expenses_time_series_by_mode",
        "historical",
    ): "service_data_and_operating_expenses_time_series_by_mode_url",
    (
        "capital_expenditures_time_series",
        "historical",
    ): "capital_expenditures_time_series_url",
}


# pulls the URL from XCom
def pull_url_from_xcom(key, context):
    try:
        task_instance = context["ti"]
        pulled_value = task_instance.xcom_pull(task_ids="scrape_ntd_xlsx_urls", key=key)
        if pulled_value is None:
            raise AirflowException(f"No URL found in XCom for key: {key}")
        print(f"Pulled value from XCom: {pulled_value}")
        return pulled_value
    except Exception as e:
        logging.error(f"Error pulling URL from XCom: {e}")
        raise AirflowException(f"Failed to pull URL from XCom: {e}")


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
            response = requests.get(validated_url)
            response.raise_for_status()  # Raises an HTTPError for bad responses
            excel_content = response.content

            if excel_content is None or len(excel_content) == 0:
                logging.info(
                    f"There is no data to download for {self.year} / {self.product}. Ending pipeline."
                )
                return None

            logging.info(
                f"Downloaded {self.product} data for {self.year} with {len(excel_content)} rows!"
            )
            return excel_content

        except requests.exceptions.HTTPError as e:
            logging.error(f"HTTP error occurred: {e}")
            raise AirflowException(f"HTTP error in XLSX download: {e}")
        except requests.exceptions.RequestException as e:
            logging.error(f"Request error occurred: {e}")
            raise AirflowException(f"Error downloading XLSX file: {e}")
        except Exception as e:
            logging.error(f"Unexpected error occurred: {e}")
            raise AirflowException(f"Unexpected error in XLSX download: {e}")


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
        *args,
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

        super().__init__(*args, **kwargs)

    def execute(self, context, *args, **kwargs):
        try:
            download_url = self.raw_excel_extract.file_url

            key = (self.product, self.year)
            if key in xcom_keys:
                download_url = pull_url_from_xcom(key=xcom_keys[key], context=context)

            logging.info(f"reading {self.product} url as {download_url}")

            excel_content = self.raw_excel_extract.fetch_from_ntd_xlsx(download_url)
            if excel_content is None:
                return None

            # Save raw content
            self.raw_excel_extract.save_content(fs=get_fs(), content=excel_content)

            # Process Excel file
            excel_data = BytesIO(excel_content)
            try:
                df_dict = pd.read_excel(excel_data, sheet_name=None, engine="openpyxl")
            except Exception as e:
                logging.error(f"Error reading Excel file: {e}")
                raise AirflowException(f"Failed to read Excel file: {e}")

            # Process each sheet
            for key, df in df_dict.items():
                try:
                    df = df.rename(make_name_bq_safe, axis="columns")
                    logging.info(f"read {df.shape[0]} rows and {df.shape[1]} columns")

                    self.clean_gzipped_content = gzip.compress(
                        df.to_json(orient="records", lines=True).encode()
                    )

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

                except Exception as e:
                    logging.error(f"Error processing sheet {key}: {e}")
                    raise AirflowException(f"Failed to process Excel sheet {key}: {e}")

        except Exception as e:
            logging.error(f"Error in XLSX operator execution: {e}")
            raise AirflowException(f"XLSX operator execution failed: {e}")
