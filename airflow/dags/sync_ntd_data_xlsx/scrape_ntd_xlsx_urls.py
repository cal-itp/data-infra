# ---
# python_callable: scrape_ntd_xlsx_urls
# provide_context: true
# ---
import logging

import requests
from bs4 import BeautifulSoup
from pydantic import HttpUrl, parse_obj_as

xlsx_urls = {
    "ridership_url": "https://www.transit.dot.gov/ntd/data-product/monthly-module-raw-data-release",
    "agency_url": "https://www.transit.dot.gov/ntd/data-product/2023-annual-database-agency-information",
    "contractual_relationship_url": "https://www.transit.dot.gov/ntd/data-product/2023-annual-database-contractual-relationship",
}


# pushes the scraped URL value to XCom
def push_url_to_xcom(key, scraped_url, context):
    task_instance = context["ti"]
    task_instance.xcom_push(key=key, value=scraped_url)


# Look for an anchor tag where the href ends with '.xlsx' and starts with '/sites/fta.dot.gov/files/'
def href_matcher(href):
    return (
        href and href.startswith("/sites/fta.dot.gov/files/") and href.endswith(".xlsx")
    )


def scrape_ntd_xlsx_urls(**context):
    for key, value in xlsx_urls.items():
        url = value
        req = requests.get(url)
        soup = BeautifulSoup(req.text, "html.parser")

        link = soup.find("a", href=href_matcher)

        # Extract the href if the link is found
        file_link = link["href"] if link else None

        updated_url = f"https://www.transit.dot.gov{file_link}"

        validated_url = parse_obj_as(HttpUrl, updated_url)

        logging.info(f"Validated URL: {validated_url}.")

        push_url_to_xcom(key=key, scraped_url=validated_url, context=context)


# # pushes the scraped URL value to XCom
# def push_url_to_xcom(scraped_url, context):
#     task_instance = context["ti"]
#     task_instance.xcom_push(key="current_url", value=scraped_url)


# # Look for an anchor tag where the href ends with '.xlsx' and starts with '/sites/fta.dot.gov/files/'
# def href_matcher(href):
#     return (
#         href and href.startswith("/sites/fta.dot.gov/files/") and href.endswith(".xlsx")
#     )


# def scrape_ntd_xlsx_urls(**context):
#     # page to find download URL
#     url = "https://www.transit.dot.gov/ntd/data-product/monthly-module-raw-data-release"
#     req = requests.get(url)
#     soup = BeautifulSoup(req.text, "html.parser")

#     link = soup.find("a", href=href_matcher)

#     # Extract the href if the link is found
#     file_link = link["href"] if link else None

#     updated_url = f"https://www.transit.dot.gov{file_link}"

#     validated_url = parse_obj_as(HttpUrl, updated_url)

#     logging.info(f"Validated URL: {validated_url}.")

#     push_url_to_xcom(scraped_url=validated_url, context=context)