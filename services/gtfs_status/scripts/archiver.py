from collections import OrderedDict
from pathlib import Path
import datetime
import requests
import threading
import time
import sys
import yaml


OUTPUT_DIR = Path(__file__).parent.parent / ".cache"
TICKINT = 20


def load_yaml_file(path):
    # TODO this needs to take file from bucket
    with open(path, "r") as f:
        return yaml.load(f, Loader=yaml.SafeLoader)


def fetch_url(url, headers, key, time_string, iter_no):
    try:
        request = requests.get(url, headers=headers)
    except Exception as e:
        print(f"\nurl failed on cycle #{iter_no}", url)
        print(e)
        return
    request.raise_for_status()
    content = request.content
    target = OUTPUT_DIR / f"{time_string}/{key}"
    target.parent.mkdir(exist_ok=True, parents=True)
    target.write_bytes(content)
    # print(int(time.time() %20))


def parse_agencies(path, key_prefix="gtfs_rt"):
    out = OrderedDict()
    yaml_data = load_yaml_file(path)
    for agency_name, agency_def in yaml_data.items():
        for i, feed_set in enumerate(agency_def["feeds"]):
            for feed_name, feed_url in feed_set.items():
                if feed_name.startswith(key_prefix) and feed_url:
                    if "key=" in feed_url.lower() or "token=" in feed_url:
                        # skipping urls with apiKey, api_key, and token for now
                        continue
                    if "api.goswift.ly" in feed_url:
                        # skipping swiftly for now
                        continue
                    agency_itp_id = agency_def["itp_id"]
                    key = "{}/{}/{}".format(agency_itp_id, i, feed_name)
                    out[key] = feed_url
    return out


def parse_headers(path):
    out = {}
    yaml_data = load_yaml_file(path)
    for item in yaml_data:
        for url_set in item["URLs"]:
            itp_id = url_set["itp_id"]
            url_number = url_set["url_number"]
            for rt_url in url_set["rt_urls"]:
                key = f"{itp_id}/{url_number}/{rt_url}"
                out[key] = item["header-data"]
    return out


def runner(agencies_path, headers_path, outof4):
    outof4 = int(outof4)
    urls_by_key = parse_agencies(agencies_path)
    headers = parse_headers(headers_path)
    iter_no = 0

    def tick():
        now = datetime.datetime.now().isoformat().split('.')[0]
        for i, (key, url) in enumerate(urls_by_key.items()):
            if i % 4 == outof4 %4:
                th = threading.Thread(
                    target=fetch_url, args=(url, headers.get(key), key, now, iter_no)
                )
                th.start()

    while True:
        iter_no += 1
        print(f"{iter_no}: sleeping", threading.active_count())
        time.sleep(TICKINT - (time.time() % TICKINT))
        tick()
        urls_by_key = parse_agencies(agencies_path)
        headers = parse_headers(headers_path)


if __name__ == "__main__":
    runner(sys.argv[1], sys.argv[2], sys.argv[3])
    # for key, url in parse_agencies(sys.argv[1]).items():
    #     print(key, url)
