"""mappers.py: Location for implementations of Mapper threads

Mapper threads are responsible for loading data from an external source (most thread
loops will want to do so on every tick event), iterating over k/v pairs of the data
yielded by a mapperfn, and building an internal map (dict) of the k/v pairs.

The get() method of a mapper instance can then safely called from other threads in order
to retrieve data from the internal map.
"""
import threading
import queue
import hashlib
import copy
import time
import yaml


class YamlMapper(threading.Thread):
    """Loads and remapse a yaml file on every tick

    Skips remapping the yaml file if it hasn't changed since the last time it was mapped
    """

    def __init__(self, logger, evtbus, yaml_path, mapperfn):

        super().__init__()

        self.logger = logger
        self.evtbus = evtbus
        self.yaml_path = yaml_path
        # mapperfn is a function which accepts the arguments (logger, yaml_data)
        # and yields zero or more ( map_key, data ) tuples
        self.mapperfn = mapperfn
        self.yaml_id = ""
        self.name = "data {}".format(yaml_path)
        self.yaml_map = {}
        self.map_writable = threading.Condition(threading.Lock())
        self.map_nreaders = 0
        self.evtq = queue.Queue()

    def load_map(self):
        """
        Opens the yaml file and checks if it matches the currently mapped data.
        If the yaml file is changed, this method rebuilds the yaml_map by iterating
        each map_key, map_data pair yielded by the mapperfn
        """

        try:
            with self.yaml_path.open("rb") as f:

                yaml_sha1 = hashlib.sha1()
                yaml_sha1.update(f.read())
                yaml_id = yaml_sha1.hexdigest()
                if yaml_id == self.yaml_id:
                    return
        except OSError as e:
            self.logger.error("data file {}: load error: {}".format(self.yaml_path, e))
            return

        try:
            with self.yaml_path.open("rb") as f:
                yaml_data = yaml.load(f, Loader=yaml.SafeLoader)
        except (OSError, yaml.YAMLError) as e:
            self.logger.error("data file {}: load error: {}".format(self.yaml_path, e))
            return

        yaml_map = {}
        for map_key, map_data in self.mapperfn(self.logger, yaml_data):
            if map_key not in yaml_map:
                yaml_map[map_key] = (yaml_id, map_data)
            else:
                map_item = yaml_map[map_key]
                map_item[1].update(map_data)

        # acquire an exclusive lock
        with self.map_writable:
            while self.map_nreaders > 0:
                self.map_writable.wait()
            self.yaml_map = yaml_map
            self.yaml_id = yaml_id

        evt = ("reload", "{} {}".format(self.yaml_path, self.yaml_id), int(time.time()))
        self.logger.info("{}: emit: {}".format(self.name, evt))
        self.evtbus.emit(evt)

    def get(self, name, default=None):
        """Thread-safe method for retrieving the data mapped to a map_key"""

        # TODO: abstract these semantics under context mgmt
        # acquire a shared lock
        with self.map_writable:
            self.map_nreaders += 1

        # work with the shared lock
        try:
            data = self.yaml_map.get(name)
            if data is None:
                return default
            else:
                return copy.deepcopy(data)
        # release the shared lock
        finally:
            with self.map_writable:
                self.map_nreaders -= 1
                if self.map_nreaders == 0:
                    self.map_writable.notify_all()

    def keys(self):
        """Thread-safe method for retrieving all map_key names from the internal map"""

        # acquire a shared lock
        with self.map_writable:
            self.map_nreaders += 1
        # work with the shared lock
        try:
            return tuple(self.yaml_map.keys())
        # release the shared lock
        finally:
            with self.map_writable:
                self.map_nreaders -= 1
                if self.map_nreaders == 0:
                    self.map_writable.notify_all()

    def __iter__(self):
        return iter(self.keys())

    def __getitem__(self, key):
        if key not in self:
            raise KeyError(key)
        return self.get(key)

    def run(self):
        self.evtbus.add_listener(self.name, "tick", self.evtq)

        evt = self.evtq.get()
        while evt is not None:

            evt_name = evt[0]
            if evt_name == "tick":
                self.load_map()
            evt = self.evtq.get()

        self.logger.debug("{}: finalized".format(self.name))
