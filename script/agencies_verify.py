import logging
import requests
import sys
import yaml

sys.path.append("services/gtfs-rt-archive/src/gtfs_rt_archive/")

from mapperfns import map_agencies_urls, map_headers  # noqa

USAGE = """
Usage:
python script/agencies_verify.py agencies.yml headers.yml [DIFF]

Arguments:
agencies.yml - Yaml file containing agencies to download
headers.yml - Yaml file mapping headers onto urls in agencies.yml
DIFF - optional git diff between two hashes (will check all urls if not provided)
"""


def main():
    logger = logging.getLogger("gtfs-rt-archive")
    successes = []
    fails = []
    changed_urls = None

    with open(sys.argv[1], "r") as f:
        agencies_yaml = yaml.load(f, Loader=yaml.SafeLoader)
        agencies = map_agencies_urls(logger, agencies_yaml, key_prefix="gtfs_")
    with open(sys.argv[2], "r") as f:
        headers = dict(list(map_headers(logger, yaml.load(f, Loader=yaml.SafeLoader))))
    if len(sys.argv) > 3:
        with open(sys.argv[3], "r") as f:
            lines = f.readlines()
            lines = [line for line in lines if line.startswith("+") and "http" in line]
            changed_urls = ["http" + line.strip().split("http")[-1] for line in lines]

    for key, url in list(agencies):
        if changed_urls is not None and url not in changed_urls:
            continue
        try:
            result = requests.get(url, headers=headers.get(key, {}))
            result.raise_for_status()
        except Exception as e:
            print(f"Failed to download {url}")
            print(f"Reason: {e}")
            fails.append(url)
            continue
        successes.append(url)
    print(f"{len(successes)}/{len(successes+fails)} urls successfully downloaded")
    if fails:
        print("Exiting with error because some urls failed to download")
        exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(USAGE)
        exit(1)
    main()
