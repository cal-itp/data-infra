import threading
import queue

class EventBus(object):
    def __init__(self, logger):

        self.lock = threading.Lock()
        self.listeners = {}
        self.logger = logger

    def add_listener(self, t_name, evt_name, evt_q):

        with self.lock:
            if evt_name in self.listeners:
                self.listeners[evt_name].add((t_name, evt_q))
            else:
                self.listeners[evt_name] = {(t_name, evt_q)}

    def rm_listener(self, t_name, evt_name, evt_q):

        with self.lock:
            if (
                evt_name in self.listeners
                and (t_name, evt_q) in self.listeners[evt_name]
            ):
                self.listeners[evt_name].remove((t_name, evt_q))
            else:
                return

    def emit(self, evt):

        evt_name = evt[0]

        with self.lock:
            for listener in self.listeners.get(evt_name, set()):
                t_name = listener[0]
                evt_q = listener[1]
                try:
                    evt_q.put_nowait(evt)
                except queue.Full:
                    self.logger.critical("{}: event dropped: {}".format(t_name, evt))
