# ---
# python_callable: scrape_ntd_ridership_xlsx_url
# provide_context: true
# ---
import logging

import requests
from bs4 import BeautifulSoup
from pydantic import HttpUrl, parse_obj_as

from airflow.models import Variable


def scrape_ntd_ridership_xlsx_url():
    # page to find download URL on
    url = "https://www.transit.dot.gov/ntd/data-product/monthly-module-raw-data-release"
    req = requests.get(url)
    soup = BeautifulSoup(req.text, "html.parser")

    # Look for an anchor tag where the href ends with '.xlsx' and starts with '/sites/fta.dot.gov/files/'
    link = soup.find(
        "a",
        href=lambda href: href
        and href.startswith("/sites/fta.dot.gov/files/")
        and href.endswith(".xlsx"),
    )

    # Extract the href if the link is found
    file_link = link["href"] if link else None

    updated_url = "https://www.transit.dot.gov" + file_link
    # print('https://www.transit.dot.gov' + file_link)

    validated_url = parse_obj_as(HttpUrl, updated_url)

    logging.info(f"Validated URL: {validated_url}.")

    # Set or overwrite the variable
    # Will this work?
    # Variable.set("CURRENT_NTD_RIDERSHIP_URL", f"'{validated_url}'")
    Variable.set("CURRENT_NTD_RIDERSHIP_URL", validated_url)
