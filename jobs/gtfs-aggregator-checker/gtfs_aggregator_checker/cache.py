import os
import urllib.error
import urllib.request
from pathlib import Path

from .utils import url_split


def get_cache_dir():
    if "GTFS_CACHE_DIR" not in os.environ:
        return None
    path = Path(os.environ["GTFS_CACHE_DIR"])
    path.mkdir(exist_ok=True, parents=True)
    return path


def get_cached(key, func, directory=None):
    if not directory:
        directory = get_cache_dir()
    if not directory:
        # cache directory is not set, execute function and return
        return func()
    path = directory / key
    if not path.exists():
        content = func()
        with open(path, "w") as f:
            f.write(content)
    with open(path, "r") as f:
        return f.read()


def curl_cached(url, key=None):
    domain, path = url_split(url)
    if key is None:
        key = path.replace("/", "__")
    if len(key) > 255:
        key = key[:255]  # max filename length is 255

    def get():
        req = urllib.request.Request(url)
        r = urllib.request.urlopen(req)
        return r.read().decode()

    cache_dir = get_cache_dir()
    if not cache_dir:
        return get()
    path = cache_dir / domain
    path.mkdir(exist_ok=True, parents=True)
    return get_cached(key, get, directory=path)
