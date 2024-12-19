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
    "contractual_relationship_url": "https://www.transit.dot.gov/ntd/data-product/2023-annual-database-contractual-relationship",
    "operating_and_capital_funding_url": "https://www.transit.dot.gov/ntd/data-product/ts12-operating-funding-time-series-3",
    "service_data_and_operating_expenses_time_series_by_mode_url": "https://www.transit.dot.gov/ntd/data-product/ts21-service-data-and-operating-expenses-time-series-mode-2",
    "capital_expenditures_time_series_url": "https://www.transit.dot.gov/ntd/data-product/ts31-capital-expenditures-time-series-2",
}


# pushes the scraped URL value to XCom
def push_url_to_xcom(key, scraped_url, context):
    try:
        task_instance = context.get("ti")
        if task_instance is None:
            raise AirflowException("Task instance not found in context")
        task_instance.xcom_push(key=key, value=scraped_url)
    except Exception as e:
        logging.error(f"Error pushing URL to XCom for key {key}: {e}")
        raise AirflowException(f"Failed to push URL to XCom: {e}")


# Look for an anchor tag where the href ends with '.xlsx' and starts with '/sites/fta.dot.gov/files/'
def href_matcher(href):
    return (
        href and href.startswith("/sites/fta.dot.gov/files/") and href.endswith(".xlsx")
    )


def scrape_ntd_xlsx_urls(**context):
    for key, url in xlsx_urls.items():
        try:
            # Make HTTP request with proper error handling
            try:
                response = requests.get(url)
                response.raise_for_status()  # Raises HTTPError for bad responses
            except requests.exceptions.HTTPError as e:
                logging.error(f"HTTP error occurred while fetching {url}: {e}")
                raise AirflowException(f"HTTP error for {key}: {e}")
            except requests.exceptions.RequestException as e:
                logging.error(f"Error occurred while fetching {url}: {e}")
                raise AirflowException(f"Request failed for {key}: {e}")

            # Parse HTML with error handling
            try:
                soup = BeautifulSoup(response.text, "html.parser")
            except Exception as e:
                logging.error(f"Error parsing HTML for {url}: {e}")
                raise AirflowException(f"HTML parsing failed for {key}: {e}")

            # Find link with error handling
            link = soup.find("a", href=href_matcher)
            if not link:
                error_msg = f"No XLSX download link found for {key} at {url}"
                logging.error(error_msg)
                raise AirflowException(error_msg)

            # Extract href with error handling
            file_link = link.get("href")
            if not file_link:
                error_msg = f"Found link for {key} but href attribute is missing"
                logging.error(error_msg)
                raise AirflowException(error_msg)

            # Construct and validate URL
            updated_url = f"https://www.transit.dot.gov{file_link}"
            try:
                validated_url = parse_obj_as(HttpUrl, updated_url)
            except ValidationError as e:
                logging.error(f"URL validation failed for {updated_url}: {e}")
                raise AirflowException(f"Invalid URL constructed for {key}: {e}")

            logging.info(f"Successfully validated URL for {key}: {validated_url}")

            # Push to XCom
            push_url_to_xcom(key=key, scraped_url=validated_url, context=context)

        except Exception as e:
            # Log any unhandled exceptions and re-raise as AirflowException
            logging.error(f"Unexpected error processing {key}: {e}")
            raise AirflowException(f"Failed to process {key}: {e}")
