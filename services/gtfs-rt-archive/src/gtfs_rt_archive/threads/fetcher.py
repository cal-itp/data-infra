import threading
import queue
import uuid
import urllib.request
import urllib.error

class PoolFetcher(threading.Thread):
    def __init__(self, logger, evtbus, qmap, gettermap, cfg_name):

        super().__init__()

        self.logger = logger
        self.evtbus = evtbus
        self.wq = qmap['write']
        self.gettermap = gettermap
        self.cfg_name = cfg_name
        self.name = "fetcher {}".format(cfg_name)
        self.evtq = queue.Queue()

    def fetch(self, txn):
        url_cfg = self.gettermap['agencies'](self.cfg_name)
        if url_cfg is None:
          # shutdown when there is no URL to fetch
          self.evtq.put(None)
          return
        url_datasrc_id = url_cfg[0]
        url = url_cfg[1]
        headers_cfg = self.gettermap['headers'](self.cfg_name)
        headers_datasrc_id = ''
        headers = {}
        if headers_cfg is not None:
          headers_datasrc_id = headers_cfg[0]
          headers = headers_cfg[1]
        self.logger.debug("{}: [txn {}] start fetch datasrc_id={} url={}".format(self.name, txn["id"], url_datasrc_id, url))
        try:
            request = urllib.request.Request(url)
            for key, value in headers.items():
                request.add_header(key, value)
            txn["input_stream"] = urllib.request.urlopen(request)
        except (urllib.error.URLError, urllib.error.HTTPError) as e:
            self.logger.warning(
                "{} {}: [txn {}] error fetching url {}: {}".format(
                    self.name, len(headers), txn["id"], url, e
                )
            )

    def run(self):

        self.evtbus.add_listener(self.name, "tick", self.evtq)

        evt = self.evtq.get()
        while evt is not None:

            evt_name = evt[0]
            if evt_name == "tick":
                txn = {"evt": evt, "input_name": self.cfg_name, "id": uuid.uuid4(), "input_stream": None}
                rs = self.fetch(txn)
                self.logger.debug("{}: [txn {}] completed fetch")
                if hasattr(txn["input_stream"], "read"):
                    self.wq.put(txn)
                else:
                  self.logger.warn("{}: [txn {}] no data fetched".format(self.name, txn["id"], txn["input_name"]))

            evt = self.evtq.get()

        self.logger.debug("{}: finalized".format(self.name))

class Fetcher(threading.Thread):
    def __init__(self, logger, evtbus, wq, urldef):

        super().__init__()

        self.logger = logger
        self.evtbus = evtbus
        self.wq = wq
        self.urldef = urldef
        self.name = "fetcher {}".format(urldef[0])
        self.evtq = queue.Queue()

    def fetch(self):
        url = self.urldef[1]
        headers = self.urldef[2]
        try:
            request = urllib.request.Request(url)
            for key, value in headers.items():
                request.add_header(key, value)
            return urllib.request.urlopen(request)
        except (urllib.error.URLError, urllib.error.HTTPError) as e:
            self.logger.warning(
                "{} {}: error fetching url {}: {}".format(
                    self.name, len(headers), url, e
                )
            )

    def run(self):

        self.evtbus.add_listener(self.name, "tick", self.evtq)

        evt = self.evtq.get()
        while evt is not None:

            evt_name = evt[0]
            if evt_name == "tick":
                rs = self.fetch()
                if hasattr(rs, "read"):
                    self.wq.put({"evt": evt, "urldef": self.urldef, "data": rs})

            evt = self.evtq.get()

        self.logger.debug("{}: finalized".format(self.name))
