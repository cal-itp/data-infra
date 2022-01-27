import threading
import queue


class ThreadPool(threading.Thread):
    """
    Binds a thread class (e.g., a Fetcher) to one or more YamlMappers which
    provide config for each instance of the thread
    """

    def __init__(self, logger, evtbus, qmap, threadcls, mappers):

        super().__init__()

        self.logger = logger
        self.evtbus = evtbus
        self.qmap = qmap
        self.threadcls = threadcls
        self.mappers = mappers
        self.poolmap = {}
        self.evtq = queue.Queue()

    def spawn(self, name):
        mapper_getters = {
            name: getattr(self.mappers[name], "get") for name in self.mappers
        }
        self.poolmap[name] = self.threadcls(
            self.logger, self.evtbus, self.qmap, mapper_getters, name
        )
        self.poolmap[name].start()

    def reconcile(self):

        threadnames = set()
        for mapper in self.mappers.values():
            threadnames.update(set(mapper.keys()))

        for name in threadnames:
            if name in self.poolmap:
                t = self.poolmap[name]
                if not t.is_alive():
                    self.logger.debug("threadpool: respawning thread: {}".format(name))
                    self.spawn(name)
            else:
                self.logger.debug("threadpool: spawning new thread: {}".format(name))
                self.spawn(name)

    def run(self):
        self.evtbus.add_listener(self.name, "reload", self.evtq)

        self.reconcile()
        evt = self.evtq.get()
        while evt is not None:

            evt_name = evt[0]
            if evt_name == "reload":
                self.reconcile()
            evt = self.evtq.get()

        self.logger.debug("{}: finalized".format(self.name))
