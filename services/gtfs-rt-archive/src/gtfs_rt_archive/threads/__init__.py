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

        txn = self.wq.get()
        while txn is not None:
            evt_ts = txn["evt"][2]
            data_name = txn["input_name"]
            data_id = "{}/{}".format(
                datetime.datetime.fromtimestamp(evt_ts).isoformat(), data_name
            )
            self.logger.debug('{}: [txn {}] begin write: data_id={} urlstr={}'.format(self.name, txn["id"], data_id, self.urlstr))
            self.write(data_id, txn["input_stream"])
            self.logger.debug('{}: [txn {}] completed write: data_id={} urlstr={}'.format(self.name, txn["id"], data_id, self.urlstr))
            txn = self.wq.get()

        self.logger.debug("{}: finalized".format(self.name))
