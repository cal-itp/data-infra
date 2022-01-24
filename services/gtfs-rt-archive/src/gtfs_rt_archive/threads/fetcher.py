import threading
import queue
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

    def fetch(self):
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
        self.logger.debug("{}: fetch datasrc_id={} url={}".format(self.name, url_datasrc_id, url))
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
        while evt is not None:

            evt_name = evt[0]
            if evt_name == "tick":
                rs = self.fetch()
                if hasattr(rs, "read"):
                    # FIXME: the writer thread still expects a urldef
                    self.wq.put({"evt": evt, "urldef": (self.cfg_name,), "data": rs})

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
            self.logger.info(
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
