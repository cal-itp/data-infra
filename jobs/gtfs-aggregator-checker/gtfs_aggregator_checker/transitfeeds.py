from urllib.error import HTTPError

from bs4 import BeautifulSoup
from tqdm import tqdm

from .cache import curl_cached

LOCATION = "67-california-usa"
ROOT = "https://transitfeeds.com"


def resolve_url(url):
    if url.startswith(ROOT):
        return url
    if url.startswith("/"):
        return f"{ROOT}{url}"
    raise ValueError("Not a transit feed url: {url}")


def get_transitfeeds_urls():
    print("fetching transit feeds URLs")

    page_urls = []
    provider_urls = []
    feed_urls = []
    results = []

    html = curl_cached(f"{ROOT}/l/{LOCATION}")
    soup = BeautifulSoup(html, "html.parser")
    for a in soup.select(".pagination a"):
        page_urls.append(resolve_url(a["href"]))

    for page_url in page_urls:
        html = curl_cached(page_url)
        soup = BeautifulSoup(html, "html.parser")
        for a in soup.select("a.btn"):
            if a["href"].startswith("/p/"):
                provider_urls.append(resolve_url(a["href"]))

    for provider_url in provider_urls:
        html = curl_cached(provider_url)
        soup = BeautifulSoup(html, "html.parser")
        for a in soup.select("a.list-group-item"):
            feed_urls.append(resolve_url(a["href"]))

    for feed_url in tqdm(feed_urls, desc="Fetching individual feed URLs"):
        try:
            html = curl_cached(feed_url)
        except HTTPError:
            print("failed to fetch:", feed_url)
            continue

        soup = BeautifulSoup(html, "html.parser")
        for a in soup.select("a"):
            url = a["href"]
            if url.startswith("/") or url.startswith(ROOT):
                continue
            results.append((feed_url, url))
    return results
