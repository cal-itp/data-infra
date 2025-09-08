# ---
# python_callable: scrape_ntd_xlsx_urls
# provide_context: true
# ---
import logging
import random
import time

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


# Updated headers to look like a real modern browser
def get_realistic_headers():
    """Generate realistic browser headers to avoid bot detection."""
    return {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br",
        "DNT": "1",
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "none",
        "Sec-Fetch-User": "?1",
        "sec-ch-ua": '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": '"macOS"',
        "Cache-Control": "max-age=0",
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


def make_http_request(url, key, max_retries=3):
    """Make HTTP request with proper error handling, timeout, and retry logic."""
    session = requests.Session()
    headers = get_realistic_headers()

    for attempt in range(max_retries + 1):
        try:
            # Add random delay between requests to avoid rate limiting
            if attempt > 0:
                delay = (2**attempt) + random.uniform(
                    0, 1
                )  # Exponential backoff with jitter
                logging.info(
                    f"Retrying {key} in {delay:.2f} seconds (attempt {attempt + 1}/{max_retries + 1})"
                )
                time.sleep(delay)

            # Increase timeout for better reliability
            response = session.get(url, headers=headers, timeout=60)
            response.raise_for_status()

            logging.info(f"Successfully fetched {key} on attempt {attempt + 1}")
            return response

        except requests.exceptions.Timeout as e:
            if attempt == max_retries:
                logging.error(f"Final timeout occurred while fetching {url}: {e}")
                raise AirflowException(
                    f"Request timeout for {key} after {max_retries + 1} attempts: The website appears to be unresponsive. {e}"
                )
            else:
                logging.warning(f"Timeout on attempt {attempt + 1} for {key}: {e}")

        except requests.exceptions.HTTPError as e:
            if e.response.status_code in [
                429,
                503,
                502,
                504,
            ]:  # Rate limiting or server errors
                if attempt == max_retries:
                    logging.error(f"HTTP error occurred while fetching {url}: {e}")
                    raise AirflowException(
                        f"HTTP error for {key} after {max_retries + 1} attempts: {e}"
                    )
                else:
                    logging.warning(
                        f"HTTP error on attempt {attempt + 1} for {key}: {e}"
                    )
            else:
                # For other HTTP errors, don't retry
                logging.error(f"HTTP error occurred while fetching {url}: {e}")
                raise AirflowException(f"HTTP error for {key}: {e}")

        except requests.exceptions.RequestException as e:
            if attempt == max_retries:
                logging.error(f"Error occurred while fetching {url}: {e}")
                raise AirflowException(
                    f"Request failed for {key} after {max_retries + 1} attempts: {e}"
                )
            else:
                logging.warning(
                    f"Request error on attempt {attempt + 1} for {key}: {e}"
                )

    # This should never be reached, but just in case
    raise AirflowException(f"Unexpected error: max retries exceeded for {key}")


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
    total_urls = len(xlsx_urls)
    processed_count = 0

    for key, url in xlsx_urls.items():
        try:
            # Add delay between different URL requests to be respectful
            if processed_count > 0:
                delay = random.uniform(2, 5)  # Random delay between 2-5 seconds
                logging.info(f"Waiting {delay:.2f} seconds before processing {key}")
                time.sleep(delay)

            logging.info(f"Processing {key} ({processed_count + 1}/{total_urls})")

            # Make HTTP request
            response = make_http_request(url, key)

            # Parse HTML content
            soup = parse_html_content(response.text, url, key)

            # Find and validate XLSX link
            validated_url = find_and_validate_xlsx_link(soup, key, url)

            logging.info(f"Successfully validated URL for {key}: {validated_url}")

            # Push to XCom
            push_url_to_xcom(key=key, scraped_url=validated_url, context=context)

            processed_count += 1

        except AirflowException:
            # Re-raise AirflowExceptions as they already have proper error messages
            raise
        except Exception as e:
            # Log any unhandled exceptions and re-raise as AirflowException
            logging.error(f"Unexpected error processing {key}: {e}")
            raise AirflowException(f"Failed to process {key}: {e}")

    logging.info(f"Successfully processed all {processed_count} URLs")
