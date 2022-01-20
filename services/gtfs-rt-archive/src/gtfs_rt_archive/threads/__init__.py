import datetime
import threading

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
