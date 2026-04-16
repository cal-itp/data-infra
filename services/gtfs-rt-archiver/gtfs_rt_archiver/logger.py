import logging
import sys


class LogLevelFilter(logging.Filter):
    def filter(self, rec):
        return rec.levelno in (logging.DEBUG, logging.INFO)


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

stdout_handler = logging.StreamHandler(sys.stdout)
stdout_handler.setLevel(logging.DEBUG)
stdout_handler.addFilter(LogLevelFilter())
logger.addHandler(stdout_handler)

stderr_handler = logging.StreamHandler()
stderr_handler.setLevel(logging.WARNING)

logger.addHandler(stderr_handler)
