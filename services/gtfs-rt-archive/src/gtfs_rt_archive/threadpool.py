import threading
import queue


class ThreadPool(threading.Thread):
    """
    Binds a thread class (e.g., a PoolFetcher) to one or more YamlMappers, each of which
    provides input data to instances of the thread class (i.e., threads in the pool)
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
        """Spawn a new instance of threadcls

        Passes a map of mapper_name, mapper_getter pairs to the new thread and passes
        the name parameter to the thread as its map_key it will use to retrieve data
        from each mapper_getter
        """

        mapper_getters = {
            name: getattr(self.mappers[name], "get") for name in self.mappers
        }
        self.poolmap[name] = self.threadcls(
            self.logger, self.evtbus, self.qmap, mapper_getters, name
        )
        self.poolmap[name].start()

    def reconcile(self):
        """Ensures a thread is spawned for each map_key in each mapper"""

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
        """Perform a reconcile() on every reload and tick event"""
        self.evtbus.add_listener(self.name, "reload", self.evtq)
        self.evtbus.add_listener(self.name, "tick", self.evtq)

        self.reconcile()
        evt = self.evtq.get()
        while evt is not None:

            evt_name = evt[0]
            if evt_name in ("tick", "reload"):
                self.reconcile()
            evt = self.evtq.get()

        self.logger.debug("{}: finalized".format(self.name))
