# ---
# python_callable: scrape_ntd_xlsx_urls
# provide_context: true
# ---
import logging
import time

import requests
from bs4 import BeautifulSoup
from pydantic.v1 import HttpUrl, ValidationError, parse_obj_as
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from airflow.exceptions import AirflowException

xlsx_urls = {
    "ridership_url": "https://www.transit.dot.gov/ntd/data-product/monthly-module-raw-data-release",
    "2022_agency_url": "https://www.transit.dot.gov/ntd/data-product/2022-annual-database-agency-information",
    "2023_agency_url": "https://www.transit.dot.gov/ntd/data-product/2023-annual-database-agency-information",
    "2024_agency_url": "https://www.transit.dot.gov/ntd/data-product/2024-annual-database-agency-information",
    "2022_contractual_relationship_url": "https://www.transit.dot.gov/ntd/data-product/2022-annual-database-contractual-relationship",
    "2023_contractual_relationship_url": "https://www.transit.dot.gov/ntd/data-product/2023-annual-database-contractual-relationship",
    "2024_contractual_relationship_url": "https://www.transit.dot.gov/ntd/data-product/2024-annual-database-contractual-relationship",
    "operating_and_capital_funding_url": "https://www.transit.dot.gov/ntd/data-product/ts12-operating-funding-time-series-3",
    "service_data_and_operating_expenses_time_series_by_mode_url": "https://www.transit.dot.gov/ntd/data-product/ts21-service-data-and-operating-expenses-time-series-mode-2",
    "capital_expenditures_time_series_url": "https://www.transit.dot.gov/ntd/data-product/ts31-capital-expenditures-time-series-2",
    "asset_inventory_time_series_url": "https://www.transit.dot.gov/ntd/data-product/ts41-asset-inventory-time-series-4",
}

# We want to look like a real browser, in this case Chrome 139
headers = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "sec-ch-ua": '"Not A;Brand"',
    "sec-fetch-dest": "document",
    "sec-fetch-mode": "navigate",
    "sec-fetch-site": "none",
    "sec-fetch-user": "?1",
}


def create_robust_session():
    """Create a requests session with retry strategy and connection pooling."""
    session = requests.Session()

    # Configure retry strategy for production resilience
    retry_strategy = Retry(
        total=3,  # Total number of retries
        status_forcelist=[429, 500, 502, 503, 504],  # HTTP status codes to retry
        backoff_factor=1,  # Wait time between retries (1, 2, 4 seconds)
        raise_on_status=False,  # Don't raise exception on retry-able status codes
    )

    # Mount adapter with retry strategy
    adapter = HTTPAdapter(
        max_retries=retry_strategy, pool_connections=10, pool_maxsize=10
    )
    session.mount("http://", adapter)
    session.mount("https://", adapter)

    return session


def push_url_to_xcom(key, scraped_url, context):
    """Push the scraped URL value to XCom with proper error handling."""
    task_instance = context.get("ti")
    if task_instance is None:
        raise AirflowException("Task instance not found in context")

    try:
        task_instance.xcom_push(key=key, value=scraped_url)
    except Exception as e:
        logging.error(f"Error pushing URL to XCom for key {key}: {e}")
        raise AirflowException(f"Failed to push URL to XCom: {e}")


def href_matcher(href):
    """Look for an anchor tag where the href ends with '.xlsx' and starts with '/sites/fta.dot.gov/files/'"""
    return (
        href and href.startswith("/sites/fta.dot.gov/files/") and href.endswith(".xlsx")
    )


def make_http_request(url, key):
    """Make HTTP request with robust error handling, retries, and extended timeout for production."""
    session = create_robust_session()

    # Increased timeout for production environments with potential network delays
    # Connect timeout: 10s, Read timeout: 60s (total max ~70s per attempt)
    timeout = (10, 60)

    max_attempts = 3
    base_delay = 2

    for attempt in range(max_attempts):
        try:
            logging.info(
                f"Attempting to fetch {url} (attempt {attempt + 1}/{max_attempts}) for {key}"
            )

            response = session.get(url, headers=headers, timeout=timeout)
            response.raise_for_status()

            logging.info(f"Successfully fetched {url} for {key}")
            return response

        except requests.exceptions.Timeout as e:
            if attempt < max_attempts - 1:
                delay = base_delay * (2**attempt)  # Exponential backoff
                logging.warning(
                    f"Timeout on attempt {attempt + 1} for {key}, retrying in {delay}s: {e}"
                )
                time.sleep(delay)
                continue
            else:
                logging.error(f"Final timeout occurred while fetching {url}: {e}")
                raise AirflowException(
                    f"Request timeout for {key} after {max_attempts} attempts: The website appears to be unresponsive. {e}"
                )

        except requests.exceptions.HTTPError as e:
            if (
                e.response.status_code in [429, 500, 502, 503, 504]
                and attempt < max_attempts - 1
            ):
                delay = base_delay * (2**attempt)
                logging.warning(
                    f"HTTP error {e.response.status_code} on attempt {attempt + 1} for {key}, retrying in {delay}s"
                )
                time.sleep(delay)
                continue
            else:
                logging.error(f"HTTP error occurred while fetching {url}: {e}")
                raise AirflowException(f"HTTP error for {key}: {e}")

        except requests.exceptions.RequestException as e:
            if attempt < max_attempts - 1:
                delay = base_delay * (2**attempt)
                logging.warning(
                    f"Request error on attempt {attempt + 1} for {key}, retrying in {delay}s: {e}"
                )
                time.sleep(delay)
                continue
            else:
                logging.error(f"Error occurred while fetching {url}: {e}")
                raise AirflowException(
                    f"Request failed for {key} after {max_attempts} attempts: {e}"
                )

    # This should never be reached, but just in case
    raise AirflowException(f"Unexpected error: All retry attempts exhausted for {key}")


def parse_html_content(response_text, url, key):
    """Parse HTML content with error handling."""
    try:
        return BeautifulSoup(response_text, "html.parser")
    except Exception as e:
        logging.error(f"Error parsing HTML for {url}: {e}")
        raise AirflowException(f"HTML parsing failed for {key}: {e}")


def find_and_validate_xlsx_link(soup, key, url):
    """Find and validate XLSX download link."""
    link = soup.find("a", href=href_matcher)
    if not link:
        error_msg = f"No XLSX download link found for {key} at {url}"
        logging.error(error_msg)
        raise AirflowException(error_msg)

    file_link = link.get("href")
    if not file_link:
        error_msg = f"Found link for {key} but href attribute is missing"
        logging.error(error_msg)
        raise AirflowException(error_msg)

    updated_url = f"https://www.transit.dot.gov{file_link}"
    try:
        return parse_obj_as(HttpUrl, updated_url)
    except ValidationError as e:
        logging.error(f"URL validation failed for {updated_url}: {e}")
        raise AirflowException(f"Invalid URL constructed for {key}: {e}")


def scrape_ntd_xlsx_urls(**context):
    """Main function to scrape XLSX URLs and push them to XCom."""
    for key, url in xlsx_urls.items():
        try:
            # Make HTTP request
            response = make_http_request(url, key)

            # Parse HTML content
            soup = parse_html_content(response.text, url, key)

            # Find and validate XLSX link
            validated_url = find_and_validate_xlsx_link(soup, key, url)

            logging.info(f"Successfully validated URL for {key}: {validated_url}")

            # Push to XCom
            push_url_to_xcom(key=key, scraped_url=validated_url, context=context)

        except AirflowException:
            # Re-raise AirflowExceptions as they already have proper error messages
            raise
        except Exception as e:
            # Log any unhandled exceptions and re-raise as AirflowException
            logging.error(f"Unexpected error processing {key}: {e}")
            raise AirflowException(f"Failed to process {key}: {e}")
