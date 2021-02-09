"""
Download the state of CA GTFS files, async version
"""
import pandas as pd
import intake
import requests
import logging
from tqdm import tqdm
import zipfile
import io
import pathlib
import datetime

catalog = intake.open_catalog("../catalogs/catalog.yml")


def make_gtfs_list():
    """
    Read in a list of GTFS urls
    from the main db
    """
    df = catalog.repository.read()
    urls = (
        df[df.GTFS.str.startswith("http")].GTFS.str.split(",").apply(pd.Series).stack()
    )
    return urls


def clean_urls(url):
    """
    take the list of urls, clean as needed
    """
    # LA Metro split requires lstrip
    if (
        url
        == "http://www.vta.org/sfc/servlet.shepherd/document/download/069A0000001NUea"
    ):
        url = "https://gtfs.vta.org/gtfs_vta.zip"
    return url.lstrip()


if __name__ == "__main__":
    run_time = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    urls = make_gtfs_list().apply(clean_urls).values
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4)"
            "AppleWebKit/537.36 (KHTML, like Gecko)"
            "Chrome/83.0.4103.97 Safari/537.36"
        )
    }
    for url in tqdm(urls):
        try:
            r = requests.get(url, headers=headers)
            r.raise_for_status()
        except requests.exceptions.HTTPError as err:
            logging.warning(f"No feed found for {url}, {err}")
        try:
            z = zipfile.ZipFile(io.BytesIO(r.content))
            # replace here with s3fs
            pathlib.Path(f"/tmp/gtfs-data/{run_time}/{url}").mkdir(
                parents=True, exist_ok=True
            )
            z.extractall(f"/tmp/gtfs-data/{run_time}/{url}")
        except zipfile.BadZipFile:
            logging.warning(f"failed to zipfile {url}")
