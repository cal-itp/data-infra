import gzip
import logging
import os
from io import BytesIO
from typing import ClassVar, Dict, List, Optional, Tuple

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
    ): "2023_contractual_relationship_url",
    (
        "annual_database_contractual_relationship",
        "2022",
    ): "2022_contractual_relationship_url",
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
    (
        "asset_inventory_time_series",
        "historical",
    ): "asset_inventory_time_series_url",
}


def pull_url_from_xcom(key: str, context: dict) -> str:
    """Pull URL from XCom with proper error handling."""
    try:
        task_instance = context["ti"]
        if task_instance is None:
            raise AirflowException("Task instance not found in context")

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

    def _make_request(self, url: str) -> bytes:
        """Make HTTP request with proper error handling."""
        try:
            response = requests.get(url)
            response.raise_for_status()
            return response.content
        except requests.exceptions.HTTPError as e:
            logging.error(f"HTTP error occurred: {e}")
            raise AirflowException(f"HTTP error in XLSX download: {e}")
        except requests.exceptions.RequestException as e:
            logging.error(f"Request error occurred: {e}")
            raise AirflowException(f"Error downloading XLSX file: {e}")

    def _validate_content(self, content: bytes) -> Optional[bytes]:
        """Validate downloaded content."""
        if content is None or len(content) == 0:
            logging.info(
                f"There is no data to download for {self.year} / {self.product}. Ending pipeline."
            )
            return None
        logging.info(
            f"Downloaded {self.product} data for {self.year} with {len(content)} rows!"
        )
        return content

    def fetch_from_ntd_xlsx(self, file_url: str) -> Optional[bytes]:
        """Fetch XLSX file with proper error handling."""
        try:
            validated_url = parse_obj_as(HttpUrl, file_url)
            logging.info(f"reading file from url {validated_url}")

            excel_content = self._make_request(validated_url)
            return self._validate_content(excel_content)

        except AirflowException:
            raise
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
        xlsx_file_url: str,
        year: str,
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

    def _get_download_url(self, context: dict) -> str:
        """Get download URL from XCom if needed."""
        download_url = self.raw_excel_extract.file_url
        key = (self.product, self.year)
        if key in xcom_keys:
            download_url = pull_url_from_xcom(key=xcom_keys[key], context=context)
        logging.info(f"reading {self.product} url as {download_url}")
        return download_url

    def _read_excel_file(self, excel_content: bytes) -> Dict[str, pd.DataFrame]:
        """Read Excel file with proper error handling."""
        try:
            excel_data = BytesIO(excel_content)
            return pd.read_excel(excel_data, sheet_name=None, engine="openpyxl")
        except Exception as e:
            logging.error(f"Error reading Excel file: {e}")
            raise AirflowException(f"Failed to read Excel file: {e}")

    def _process_sheet(self, sheet_name: str, df: pd.DataFrame) -> Tuple[str, bytes]:
        """Process a single Excel sheet with proper error handling."""
        try:
            df = df.rename(make_name_bq_safe, axis="columns")
            logging.info(f"read {df.shape[0]} rows and {df.shape[1]} columns")

            gzipped_content = gzip.compress(
                df.to_json(orient="records", lines=True).encode()
            )

            tab_name = make_name_bq_safe(sheet_name)
            return tab_name, gzipped_content
        except Exception as e:
            logging.error(f"Error processing sheet {sheet_name}: {e}")
            raise AirflowException(f"Failed to process Excel sheet {sheet_name}: {e}")

    def _save_processed_sheet(self, tab_name: str, gzipped_content: bytes) -> None:
        """Save processed sheet with proper error handling."""
        try:
            clean_excel_extract = CleanExtract(
                year=self.year,
                product=self.product + "/" + self.year + "/" + tab_name,
                filename=f"{self.year}__{self.product}__{tab_name}.jsonl.gz",
            )
            clean_excel_extract.save_content(fs=get_fs(), content=gzipped_content)
        except Exception as e:
            logging.error(f"Error saving processed sheet {tab_name}: {e}")
            raise AirflowException(f"Failed to save processed sheet {tab_name}: {e}")

    def execute(self, context: dict, *args, **kwargs) -> None:
        """Execute the operator with proper error handling."""
        try:
            # Get download URL
            download_url = self._get_download_url(context)

            # Download Excel file
            excel_content = self.raw_excel_extract.fetch_from_ntd_xlsx(download_url)
            if excel_content is None:
                return None

            # Save raw content
            self.raw_excel_extract.save_content(fs=get_fs(), content=excel_content)

            # Read Excel file
            df_dict = self._read_excel_file(excel_content)

            # Process each sheet
            for sheet_name, df in df_dict.items():
                tab_name, gzipped_content = self._process_sheet(sheet_name, df)
                self._save_processed_sheet(tab_name, gzipped_content)

        except AirflowException:
            # Re-raise AirflowExceptions as they already have proper error messages
            raise
        except Exception as e:
            logging.error(f"Error in XLSX operator execution: {e}")
            raise AirflowException(f"XLSX operator execution failed: {e}")
