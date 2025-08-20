# ---
# python_callable: scrape_ntd_xlsx_urls
# provide_context: true
# ---
import logging

import requests
from bs4 import BeautifulSoup
from pydantic import HttpUrl, ValidationError, parse_obj_as

from airflow.exceptions import AirflowException

xlsx_urls = {
    "ridership_url": "https://www.transit.dot.gov/ntd/data-product/monthly-module-raw-data-release",
    "2022_agency_url": "https://www.transit.dot.gov/ntd/data-product/2022-annual-database-agency-information",
    "2023_agency_url": "https://www.transit.dot.gov/ntd/data-product/2023-annual-database-agency-information",
    "2023_contractual_relationship_url": "https://www.transit.dot.gov/ntd/data-product/2023-annual-database-contractual-relationship",
    "2022_contractual_relationship_url": "https://www.transit.dot.gov/ntd/data-product/2022-annual-database-contractual-relationship",
    "operating_and_capital_funding_url": "https://www.transit.dot.gov/ntd/data-product/ts12-operating-funding-time-series-3",
    "service_data_and_operating_expenses_time_series_by_mode_url": "https://www.transit.dot.gov/ntd/data-product/ts21-service-data-and-operating-expenses-time-series-mode-2",
    "capital_expenditures_time_series_url": "https://www.transit.dot.gov/ntd/data-product/ts31-capital-expenditures-time-series-2",
    "asset_inventory_time_series_url": "https://www.transit.dot.gov/ntd/data-product/ts41-asset-inventory-time-series-4",
}

# We want to look like a real browser, in this case Chrome 139
headers = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
    "sec-ch-ua": '"Not A;Brand"',
    "sec-fetch-dest": "document",
    "sec-fetch-mode": "navigate",
    "sec-fetch-site": "none",
    "sec-fetch-user": "?1",
}


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
    """Make HTTP request with proper error handling."""
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response
    except requests.exceptions.HTTPError as e:
        logging.error(f"HTTP error occurred while fetching {url}: {e}")
        raise AirflowException(f"HTTP error for {key}: {e}")
    except requests.exceptions.RequestException as e:
        logging.error(f"Error occurred while fetching {url}: {e}")
        raise AirflowException(f"Request failed for {key}: {e}")


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
