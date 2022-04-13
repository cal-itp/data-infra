import json
from typing import List, Tuple

from tqdm import tqdm

from .cache import curl_cached
from .config import env

API_KEY = env.get("TRANSITLAND_API_KEY")
BASE_URL = f"https://transit.land/api/v2/rest/feeds?apikey={API_KEY}"
BASE_URL += "&limit=1000"


def get_feeds(after=None):
    url = BASE_URL
    if after:
        url += f"&after={after}"
    text = curl_cached(url, key=f"feeds_after__{after}")
    data = json.loads(text)
    results = []
    for feed in data["feeds"]:
        for urls in feed["urls"].values():
            if isinstance(urls, str):
                urls = [urls]
            for url in urls:
                results.append(
                    (f"https://transit.land/feeds/{feed['onestop_id']}", url)
                )
    after = None
    if "meta" in data:
        after = data["meta"]["after"]
    return list(results), after


def get_transitland_urls() -> List[Tuple[str, str]]:
    print("fetching transitland URLs")
    if not API_KEY:
        raise RuntimeError("TRANSITLAND_API_KEY must be set")

    max_requests = 10
    after = None
    urls = []

    for _ in tqdm(range(max_requests), desc=f"paging up to {max_requests} times"):
        new_urls, after = get_feeds(after)
        urls += new_urls
        if not after:
            break
    else:
        print("WARNING: hit loop limit for transitland")
    return urls
