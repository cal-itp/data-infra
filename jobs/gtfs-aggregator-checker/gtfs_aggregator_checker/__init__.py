import urllib.error
import urllib.parse
import urllib.request
from collections import OrderedDict

import yaml

from .transitfeeds import get_transitfeeds_urls
from .transitland import get_transitland_urls

__version__ = "1.0.1"
SECRET_PARAMS = ["api_key", "token", "apiKey", "key"]


def clean_url(url):
    if not url:
        raise Exception()
    url = urllib.parse.urlparse(url)
    query = urllib.parse.parse_qs(url.query, keep_blank_values=True)
    for param in SECRET_PARAMS:
        query.pop(param, None)
    query = OrderedDict(sorted(query.items()))
    query_string = urllib.parse.urlencode(query, True)
    url = url._replace(query=query_string, scheme="https")
    return urllib.parse.urlunparse(url)


def check_feeds(yml_file=None, csv_file=None, url=None, progress=False):
    results = {}

    if url:
        url = clean_url(url)
        results[url] = {
            "transitfeeds": {"status": "missing"},
            "transitland": {"status": "missing"},
        }
    elif csv_file:
        with open(csv_file, "r") as f:
            urls = f.read().strip().splitlines()
            for url in urls:
                url = clean_url(url)
                results[url] = {
                    "transitfeeds": {"status": "missing"},
                    "transitland": {"status": "missing"},
                }
    else:
        with open(yml_file, "r") as f:
            agencies_obj = yaml.load(f, Loader=yaml.SafeLoader)
            for agency in agencies_obj.values():
                for feed in agency["feeds"]:
                    for url_number, (url_type, url) in enumerate(feed.items()):
                        if not url:
                            continue
                        url = clean_url(url)
                        results[url] = {
                            "url_type": url_type,
                            "itp_id": agency["itp_id"],
                            "url_number": url_number,
                            "transitfeeds": {"status": "missing"},
                            "transitland": {"status": "missing"},
                        }

    for public_web_url, url in get_transitland_urls(progress=progress):
        if not url:
            continue
        url = clean_url(url)
        if url in results:
            results[url]["transitland"] = {
                "status": "present",
                "public_web_url": public_web_url,
            }

    for public_web_url, url in get_transitfeeds_urls(progress=progress):
        if not url:
            continue
        url = clean_url(url)
        if url in results:
            results[url]["transitfeeds"] = {
                "status": "present",
                "public_web_url": public_web_url,
            }

    return results
