import os
import sys
import time
from enum import Enum

import typer


class Action(str, Enum):
    fetch = "fetch"
    tick = "tick"


def check_liveness(
    action: Action, max_seconds: int = os.getenv("MAX_LIVENESS_FILE_AGE_SECONDS")
):
    now = time.time()
    if action == Action.fetch:
        file_to_check = os.environ["LAST_FETCH_FILE"]
    elif action == Action.tick:
        file_to_check = os.environ["LAST_TICK_FILE"]

    file_last_modified = os.stat(file_to_check).st_mtime
    print(now - file_last_modified)

    if now - file_last_modified > max_seconds:
        sys.exit(1)


if __name__ == "__main__":
    typer.run(check_liveness)
