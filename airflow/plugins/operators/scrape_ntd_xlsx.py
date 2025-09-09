import gzip
import logging
import os
import time
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
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from airflow.exceptions import AirflowException
from airflow.models import BaseOperator  # type: ignore

RAW_XLSX_BUCKET = os.environ["CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"]
CLEAN_XLSX_BUCKET = os.environ["CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"]

headers = {
    "User-Agent": "CalITP/1.0.0",
    "Accept": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,*/*",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "sec-ch-ua": '"CalITP";v="1"',
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": '"macOS"',
}


def create_robust_download_session():
    """Create a requests session optimized for large file downloads with retry strategy."""
    session = requests.Session()

    # Configure retry strategy for production resilience
    retry_strategy = Retry(
        total=3,  # Total number of retries
        status_forcelist=[429, 500, 502, 503, 504],  # HTTP status codes to retry
        backoff_factor=1,  # Wait time between retries (1, 2, 4 seconds)
        raise_on_status=False,  # Don't raise exception on retry-able status codes
    )

    # Mount adapter with retry strategy and larger connection pool for file downloads
    adapter = HTTPAdapter(
        max_retries=retry_strategy, pool_connections=5, pool_maxsize=5
    )
    session.mount("http://", adapter)
    session.mount("https://", adapter)

    return session


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
        """Make HTTP request with robust error handling, retries, and optimized timeout for large file downloads."""
        # Create a fresh session for each download attempt to avoid connection reuse issues
        session = requests.Session()

        # Disable urllib3 retries to handle retries at our level
        from requests.adapters import HTTPAdapter
        from urllib3.util.retry import Retry

        retry_strategy = Retry(total=0)  # Disable urllib3 retries
        adapter = HTTPAdapter(
            max_retries=retry_strategy, pool_connections=1, pool_maxsize=1
        )
        session.mount("http://", adapter)
        session.mount("https://", adapter)

        # Shorter timeout but more attempts - better for unreliable connections
        # Connect timeout: 30s, Read timeout: 120s (2 minutes) per attempt
        timeout = (30, 120)

        max_attempts = 5  # More attempts with shorter timeouts
        base_delay = 5

        for attempt in range(max_attempts):
            try:
                logging.info(
                    f"Attempting to download XLSX file from {url} (attempt {attempt + 1}/{max_attempts})"
                )

                response = session.get(
                    url, headers=headers, timeout=timeout, stream=True
                )
                response.raise_for_status()

                # Download content in chunks with progress tracking
                content = b""
                content_length = response.headers.get("content-length")
                if content_length:
                    total_size = int(content_length)
                    logging.info(f"Downloading file of size: {total_size:,} bytes")
                else:
                    total_size = None
                    logging.info("Downloading file (size unknown)")

                downloaded = 0
                chunk_size = 32768  # 32KB chunks for better performance

                for chunk in response.iter_content(chunk_size=chunk_size):
                    if chunk:  # filter out keep-alive chunks
                        content += chunk
                        downloaded += len(chunk)

                        # Log progress every 10MB
                        if downloaded % (10 * 1024 * 1024) == 0:
                            if total_size:
                                progress = (downloaded / total_size) * 100
                                logging.info(
                                    f"Download progress: {downloaded:,} / {total_size:,} bytes ({progress:.1f}%)"
                                )
                            else:
                                logging.info(f"Download progress: {downloaded:,} bytes")

                logging.info(
                    f"Successfully downloaded XLSX file ({len(content):,} bytes)"
                )
                return content

            except (
                requests.exceptions.Timeout,
                requests.exceptions.ConnectionError,
            ) as e:
                if attempt < max_attempts - 1:
                    delay = base_delay * (
                        2**attempt
                    )  # Exponential backoff: 5s, 10s, 20s, 40s
                    logging.warning(
                        f"Network error on attempt {attempt + 1} for XLSX download, retrying in {delay}s: {e}"
                    )
                    time.sleep(delay)
                    continue
                else:
                    logging.error(
                        f"Final network error occurred while downloading XLSX file: {e}"
                    )
                    raise AirflowException(
                        f"XLSX download failed after {max_attempts} attempts due to network issues: {e}"
                    )

            except requests.exceptions.HTTPError as e:
                if (
                    e.response.status_code in [429, 500, 502, 503, 504]
                    and attempt < max_attempts - 1
                ):
                    delay = base_delay * (2**attempt)
                    logging.warning(
                        f"HTTP error {e.response.status_code} on attempt {attempt + 1} for XLSX download, retrying in {delay}s"
                    )
                    time.sleep(delay)
                    continue
                else:
                    logging.error(
                        f"HTTP error occurred while downloading XLSX file: {e}"
                    )
                    raise AirflowException(f"HTTP error in XLSX download: {e}")

            except requests.exceptions.RequestException as e:
                if attempt < max_attempts - 1:
                    delay = base_delay * (2**attempt)
                    logging.warning(
                        f"Request error on attempt {attempt + 1} for XLSX download, retrying in {delay}s: {e}"
                    )
                    time.sleep(delay)
                    continue
                else:
                    logging.error(
                        f"Request error occurred while downloading XLSX file: {e}"
                    )
                    raise AirflowException(
                        f"Error downloading XLSX file after {max_attempts} attempts: {e}"
                    )
            finally:
                # Always close the session to free resources
                session.close()

        # This should never be reached, but just in case
        raise AirflowException(
            "Unexpected error: All retry attempts exhausted for XLSX download"
        )

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
