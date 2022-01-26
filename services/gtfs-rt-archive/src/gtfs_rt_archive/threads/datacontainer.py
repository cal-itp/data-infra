import threading
import queue
import hashlib
import copy
import time
import yaml

class DataContainer(threading.Thread):
    def __init__(self, logger, evtbus, datasrc_path, datasrc_parser):

        super().__init__()

        self.logger = logger
        self.evtbus = evtbus
        self.datasrc_path = datasrc_path
        # datasrc_parser is a function which accepts the arguments (logger, datasrc_data)
        # and yields zero or more ( data_name, data ) tuples
        self.datasrc_parser = datasrc_parser
        self.datasrc_id = ''
        self.name = "data {}".format(datasrc_path)
        self.data_map = {}
        self.map_writable = threading.Condition(threading.Lock())
        self.map_nreaders = 0
        self.evtq = queue.Queue()

    def load_datasrc(self):
        '''
        Opens the datasrc file and checks if it matches the currently loaded data.
        If the datasrc file is changed, this method rebuilds the data_map by iterating
        each ( data_name, data ) pair yielded by the datasrc_parser
        '''

        with self.datasrc_path.open('rb') as f:

          datasrc_sha1 = hashlib.sha1()
          datasrc_sha1.update(f.read())
          datasrc_id = datasrc_sha1.hexdigest()
          if datasrc_id == self.datasrc_id:
            return

        datasrc_ext = str(self.datasrc_path).rsplit('.', 1)[-1]

        if datasrc_ext == str(self.datasrc_path):
          datasrc_ext = ''

        if datasrc_ext in ['yml', 'yaml']:
          with self.datasrc_path.open('rb') as f:
            datasrc_data = yaml.load(f, Loader=yaml.SafeLoader)
        else:
          self.logger.warning("data file {}: skipped loading: unsupported file type".format(self.datasrc_path))
          return

        data_map = {}
        for data_name, data in self.datasrc_parser(self.logger, datasrc_data):
          if data_name not in data_map:
            data_map[data_name] = ( datasrc_id, data )
          else:
            map_item = data_map[data_name]
            map_item[1].update(data)

        # acquire an exclusive lock
        with self.map_writable:
          while self.map_nreaders > 0:
            self.map_writable.wait()
          self.data_map = data_map
          self.datasrc_id = datasrc_id

        evt = ("reload", "{} {}".format(self.datasrc_path, self.datasrc_id), int(time.time()))
        self.logger.debug("{}: emit: {}".format(self.name, evt))
        self.evtbus.emit(evt)

    def get_data(self, name):

      # TODO: abstract these semantics under context mgmt
      # acquire a shared lock
      with self.map_writable:
        self.map_nreaders+=1

      # work with the shared lock
      try:
        data = self.data_map.get(name)
        if data is None:
          return None
        else:
          return copy.deepcopy(data)
      # release the shared lock
      finally:
        with self.map_writable:
          self.map_nreaders-=1
          if self.map_nreaders == 0:
            self.map_writable.notify_all()

    def get_names(self):
      # acquire a shared lock
      with self.map_writable:
        self.map_nreaders+=1
      # work with the shared lock
      try:
        return tuple(self.data_map.keys())
      # release the shared lock
      finally:
        with self.map_writable:
          self.map_nreaders-=1
          if self.map_nreaders == 0:
            self.map_writable.notify_all()

    def run(self):
      self.evtbus.add_listener(self.name, "tick", self.evtq)

      evt = self.evtq.get()
      while evt is not None:

          evt_name = evt[0]
          if evt_name == "tick":
              self.load_datasrc()
          evt = self.evtq.get()

      self.logger.debug("{}: finalized".format(self.name))
