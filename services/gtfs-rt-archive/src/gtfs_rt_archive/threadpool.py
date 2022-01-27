import threading
import queue

class ThreadPool(threading.Thread):
    '''
    Binds a thread class (e.g., a Fetcher) to one or more YamlMappers which
    provide config for each instance of the thread
    '''
    def __init__(self, logger, evtbus, qmap, threadcls, threadcfg_container_map):

        super().__init__()

        self.logger = logger
        self.evtbus = evtbus
        self.qmap = qmap
        self.threadcls = threadcls
        self.threadcfg_container_map = threadcfg_container_map
        self.poolmap = {}
        self.evtq = queue.Queue()

    def spawn(self, name):
      cfg_getter_map = { name: getattr(self.threadcfg_container_map[name], 'get_data') for name in self.threadcfg_container_map }
      self.poolmap[name] = self.threadcls(self.logger, self.evtbus, self.qmap, cfg_getter_map, name)
      self.poolmap[name].start()

    def reconcile(self):

      threadnames = set()
      for container in self.threadcfg_container_map.values():
        threadnames.update(set(container.get_names()))

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
