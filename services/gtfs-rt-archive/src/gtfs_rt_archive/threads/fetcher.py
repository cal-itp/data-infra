"""fetcher.py: Fetcher implementations

A Fetcher is a thread which retrieves a data file from a remote location, beginning the
data file transaction. Each Fetcher should implement a fetch() method which accepts a
txn object (dict) and maps a readable I/O stream into the txn object under the
"input_stream" key.
"""
import threading
import queue
import uuid
import urllib.request
import urllib.error


class PoolFetcher(threading.Thread):
    """A Fetcher implementation intended to be spawned by a ThreadPool

    Expected to be instantiated with getters named 'urls' and 'headers' in order to
    retrieve the data it requires to perform a request. Shuts itself down if it cannot
    get a url from the 'urls' getter.
    """

    def __init__(self, logger, evtbus, qmap, mapper_getters, mapper_key):

        super().__init__()

        self.logger = logger
        self.evtbus = evtbus
        self.wq = qmap["write"]
        self.mapper_getters = mapper_getters
        self.mapper_key = mapper_key
        self.name = "fetcher {}".format(mapper_key)
        self.evtq = queue.Queue()

    def fetch(self, txn):
        url_mapval = self.mapper_getters["urls"](self.mapper_key)
        if url_mapval is None:
            # shutdown when there is no URL to fetch
            self.logger.debug(
                "{}: no url for {}: queue shutdown".format(self.name, self.mapper_key)
            )
            self.evtq.put(None)
            return
        url_yaml_id = url_mapval[0]
        url = url_mapval[1]
        headers_mapval = self.mapper_getters["headers"](self.mapper_key)
        headers_yaml_id = ""
        headers = {}
        if headers_mapval is not None:
            headers_yaml_id = headers_mapval[0]
            headers = headers_mapval[1]
        self.logger.debug(
            "[txn {}] start fetch: mapper_key={} url={} len(headers)={} url_yaml_id={} "
            "headers_yaml_id={}".format(
                txn["id"],
                self.mapper_key,
                url,
                len(headers),
                url_yaml_id,
                headers_yaml_id,
            )
        )
        try:
            request = urllib.request.Request(url)
            for key, value in headers.items():
                request.add_header(key, value)
            txn["input_stream"] = urllib.request.urlopen(request)
        except (urllib.error.URLError, urllib.error.HTTPError) as e:
            txn["input_stream"] = None
            self.logger.warning(
                "[txn {}] len(headers)={} error fetching url {}: {}".format(
                    txn["id"], len(headers), url, e
                )
            )

    def run(self):

        self.evtbus.add_listener(self.name, "tick", self.evtq)

        evt = self.evtq.get()
        while evt is not None:

            evt_name = evt[0]
            if evt_name == "tick":
                txn = {
                    "evt": evt,
                    "input_name": self.mapper_key,
                    "id": uuid.uuid4(),
                    "input_stream": None,
                }
                self.fetch(txn)
                self.logger.debug("[txn {}] completed fetch".format(txn["id"]))
                if hasattr(txn["input_stream"], "read"):
                    self.wq.put(txn)
                else:
                    self.logger.warn("[txn {}] no data fetched".format(txn["id"]))

            evt = self.evtq.get()

        self.logger.debug("{}: finalized".format(self.name))
