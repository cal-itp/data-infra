import os
import sys
import time
import datetime
import logging
import pathlib
import threading
import queue
import yaml
import urllib.request
import urllib.error
import urllib.parse


class Runner:
    def __init__(self, logger, evtbus, wq):
        self.logger = logger
        self.evtbus = evtbus
        self.wq = wq
        self.fetchers = []
        self.feeds = []

        self.agencies_path = os.getenv("CALITP_AGENCIES_YML", "agencies.yml")
        self.headers_path = os.getenv("CALITP_HEADERS_YML", "headers.yml")
        self.feeds_src = pathlib.Path(self.agencies_path)
        self.headers_src = pathlib.Path(self.headers_path)

    def tick(self):
        self.headers = self.parse_headers()
        feeds = self.parse_feeds()
        if self.feeds != feeds:
            self.feeds = feeds
            self.reset()

    def reset(self):
        fetchers = len(self.fetchers)
        feeds = len(self.feeds)
        self.logger.info(f"Removing {fetchers} old feeds and adding {feeds} new feeds")
        for fetcher in self.fetchers:
            fetcher.stop()

        self.fetchers = []
        for feed in self.feeds:
            fetcher = Fetcher(self.logger, self.evtbus, self.wq, feed)
            fetcher.start()
            self.fetchers.append(fetcher)

    def get_headers_yml(self):
        with self.headers_src.open() as f:
            return yaml.load(f, Loader=yaml.SafeLoader)

    def get_agencies_yml(self):
        with self.feeds_src.open() as f:
            return yaml.load(f, Loader=yaml.SafeLoader)

    def parse_headers(self):

        headers = {}

        headers_yml = self.get_headers_yml()
        for item in headers_yml:
            for url_set in item["URLs"]:
                itp_id = url_set["itp_id"]
                url_number = url_set["url_number"]
                for rt_url in url_set["rt_urls"]:
                    key = f"{itp_id}/{url_number}/{rt_url}"
                    if key in headers:
                        raise ValueError(
                            f"Duplicate header data for url with key: {key}"
                        )
                    headers[key] = item["header-data"]

        return headers

    def parse_feeds(self):

        feeds = []
        agencies_yml = self.get_agencies_yml()
        for agency_name, agency_def in agencies_yml.items():

            if "feeds" not in agency_def:
                self.logger.warning(
                    "agency {}: skipped loading "
                    "invalid definition (missing feeds)".format(agency_name)
                )
                continue

            if "itp_id" not in agency_def:
                self.logger.warning(
                    "agency {}: skipped loading "
                    "invalid definition (missing itp_id)".format(agency_name)
                )
                continue

            for i, feed_set in enumerate(agency_def["feeds"]):
                for feed_name, feed_url in feed_set.items():
                    if feed_name.startswith("gtfs_rt") and feed_url:

                        agency_itp_id = agency_def["itp_id"]
                        key = "{}/{}/{}".format(agency_itp_id, i, feed_name)
                        feeds.append((key, feed_url, self.headers.get(key, {}),))

        return feeds


def main(argv):

    # Config tables

    level_table = {
        "debug": logging.DEBUG,
        "info": logging.INFO,
        "warning": logging.WARNING,
        "error": logging.ERROR,
        "critical": logging.CRITICAL,
    }

    backends_table = {"file://": FSWriter, "gs://": GCPBucketWriter}

    # Setup logging channel

    logger = logging.getLogger(argv[0])

    level_name = os.getenv("CALITP_LOG_LEVEL")
    if hasattr(level_name, "lower"):
        level_name = level_name.lower()
    level = level_table.get(level_name, logging.WARNING)

    logging.basicConfig(stream=sys.stdout, level=level)

    # Parse environment

    tickint = os.getenv("CALITP_TICK_INT")
    data_dest = os.getenv("CALITP_DATA_DEST")
    secret = os.getenv("CALITP_DATA_DEST_SECRET")

    if tickint:
        tickint = int(tickint)
    else:
        tickint = 20

    if not data_dest:
        data_dest = "file:///dev/null"

    # Instantiate threads

    wq = queue.Queue()
    evtbus = EventBus(logger)
    ticker = Ticker(logger, evtbus, tickint)
    writer = None

    for scheme in backends_table:
        if data_dest.startswith(scheme):
            writercls = backends_table[scheme]
            writer = writercls(logger, wq, data_dest, secret)
            break

    if writer is None:
        logger.warning(
            "unsupported CALITP_DATA_DEST: "
            "{}: using default value file:///dev/null".format(data_dest)
        )
        writer = FSWriter(logger, wq, "file:///dev/null")

    # Run
    ticker.runner = Runner(logger, evtbus, wq)
    writer.start()
    ticker.start()
    ticker.join()


class EventBus(object):
    def __init__(self, logger):

        self.lock = threading.Lock()
        self.listeners = {}
        self.logger = logger

    def add_listener(self, t_name, evt_name, evt_q):

        with self.lock:
            if evt_name in self.listeners:
                self.listeners[evt_name].add((t_name, evt_q))
            else:
                self.listeners[evt_name] = {(t_name, evt_q)}

    def rm_listener(self, t_name, evt_name, evt_q):

        with self.lock:
            if (
                evt_name in self.listeners
                and (t_name, evt_q) in self.listeners[evt_name]
            ):
                self.listeners[evt_name].remove((t_name, evt_q))
            else:
                return

    def emit(self, evt):

        evt_name = evt[0]

        with self.lock:
            for listener in self.listeners.get(evt_name, set()):
                t_name = listener[0]
                evt_q = listener[1]
                try:
                    evt_q.put_nowait(evt)
                except queue.Full:
                    self.logger.warning("{}: event dropped: {}".format(t_name, evt))


class Ticker(threading.Thread):
    def __init__(self, logger, evtbus, tickint):

        super().__init__()

        self.logger = logger
        self.evtbus = evtbus
        self.tickint = tickint
        self.name = "ticker"
        self.tickid = 0

    def tick(self):
        evt = ("tick", self.tickid, int(time.time()))
        self.logger.debug("{}: emit: {}".format(self.name, evt))
        self.evtbus.emit(evt)
        self.tickid += 1
        self.runner.tick()

    def run(self):

        self.tickid = 0
        self.tick()

        while time.sleep(self.tickint) is None:
            self.tick()


class Fetcher(threading.Thread):
    def __init__(self, logger, evtbus, wq, urldef):

        super().__init__()
        self.logger = logger
        self.evtbus = evtbus
        self.wq = wq
        self.urldef = urldef
        self.name = "fetcher {}".format(urldef[0])
        self.evtq = queue.Queue()
        self.stopped = False

    def fetch(self):
        url = self.urldef[1]
        headers = self.urldef[2]
        try:
            request = urllib.request.Request(url)
            for key, value in headers.items():
                request.add_header(key, value)
            return urllib.request.urlopen(request)
        except (urllib.error.URLError, urllib.error.HTTPError) as e:
            self.logger.info(
                "{} {}: error fetching url {}: {}".format(
                    self.name, len(headers), url, e
                )
            )

    def run(self):

        self.evtbus.add_listener(self.name, "tick", self.evtq)

        evt = self.evtq.get()
        while evt is not None and not self.stopped:

            evt_name = evt[0]
            if evt_name == "tick":
                rs = self.fetch()
                if hasattr(rs, "read"):
                    self.wq.put({"evt": evt, "urldef": self.urldef, "data": rs})

            evt = self.evtq.get()

        self.logger.debug("{}: finalized".format(self.name))

    def stop(self):
        self.stopped = True


class BaseWriter(threading.Thread):
    def __init__(self, logger, wq, urlstr, secret=None):
        super().__init__()

        self.logger = logger
        self.wq = wq
        self.urlstr = urlstr
        self.secret = secret

    def write(self, name, rstream):
        raise NotImplementedError

    def run(self):
        item = self.wq.get()
        while item is not None:
            evt_ts = item["evt"][2]
            data_name = item["urldef"][0]
            data_id = "{}/{}".format(
                datetime.datetime.fromtimestamp(evt_ts).isoformat(), data_name
            )
            self.write(data_id, item["data"])
            item = self.wq.get()

        self.logger.debug("{}: finalized".format(self.name))


class FSWriter(BaseWriter):

    name = "filewriter"

    def __init__(self, logger, wq, urlstr, secret=None):

        super().__init__(logger, wq, urlstr, secret)

        url = urllib.parse.urlparse(urlstr)
        self.basepath = pathlib.Path(url.path)

    def write(self, name, rstream):

        dest = pathlib.Path(self.basepath, name)

        if self.basepath == pathlib.Path("/dev/null"):
            dest = self.basepath

        try:
            dest.parent.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            self.logger.error("{}: mkdir: {}: {}".format(self.name, dest.parent, e))
            return

        try:
            with dest.open(mode="wb") as f:
                f.write(rstream.read())
        except OSError as e:
            self.logger.error("{}: write: {}: {}".format(self.name, dest, e))
            return


class GCPBucketWriter(BaseWriter):

    name = "gswriter"
    baseurl = "https://storage.googleapis.com/upload/storage/v1/b"

    def __init__(self, logger, wq, urlstr, secret=None):

        super().__init__(logger, wq, urlstr, secret)

        self.session = None

        if self.secret is not None:
            from google.oauth2 import service_account
            from google.auth.transport.requests import AuthorizedSession
            from google.auth.exceptions import TransportError

            scopes = ["https://www.googleapis.com/auth/devstorage.read_write"]
            credentials = service_account.Credentials.from_service_account_file(
                secret, scopes=scopes
            )
            self.session = AuthorizedSession(credentials)
            self.GoogleAuthTransportError = TransportError

        url = urllib.parse.urlparse(urlstr)

        self.uploadurl = "{}/{}/o".format(self.baseurl, url.netloc)
        self.basepath = url.path

        while self.basepath.startswith("/"):
            self.basepath = self.basepath[1:]

        if self.basepath and not self.basepath.endswith("/"):
            self.basepath += "/"

    def write(self, name, rstream):

        rqurl = "{}?uploadType=media&name={}{}".format(
            self.uploadurl, self.basepath, name
        )
        rqheaders = {"Content-Type": "application/octet-stream"}

        if self.session is None:

            rq = urllib.request.Request(
                rqurl, method="POST", headers=rqheaders, data=rstream
            )
            try:
                urllib.request.urlopen(rq)
            except (urllib.error.URLError, urllib.error.HTTPError) as e:
                self.logger.error(
                    "{}: error uploading to bucket {}: {}".format(
                        self.name, self.urlstr, e
                    )
                )

        else:

            try:
                self.session.request("POST", rqurl, data=rstream, headers=rqheaders)
            except self.GoogleAuthTransportError as e:
                self.logger.error(
                    "{}: error uploading to bucket {}: {}".format(
                        self.name, self.urlstr, e
                    )
                )


if __name__ == "__main__":
    main(sys.argv)
