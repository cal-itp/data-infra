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
            write_name = "{}/{}".format(
                datetime.datetime.fromtimestamp(evt_ts).isoformat(), data_name
            )
            self.logger.debug('[txn {}] begin write: name={} urlstr={}'.format(txn["id"], write_name, self.urlstr))
            self.write(write_name, txn)
            self.logger.debug('[txn {}] completed write'.format(txn["id"]))
            txn = self.wq.get()

        self.logger.debug("{}: finalized".format(self.name))
