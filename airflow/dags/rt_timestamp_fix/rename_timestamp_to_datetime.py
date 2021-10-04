# ---
# python_callable: main
# ---

import time

from multiprocessing.pool import ThreadPool


def poll_task(f, timeout):
    pool = ThreadPool(processes=1)
    task = pool.apply_async(f)

    while not task.ready():
        if timeout <= 0:
            raise TimeoutError("Function %s did not complete" % f)

        time.sleep(30)
        timeout -= 30

        print("waiting...")

    return task.get()


# Note that gusty seems to require a top level function, due to how it exec's tasks
# see https://github.com/chriscardillo/gusty/issues/33
def main():
    from calitp.storage import get_fs
    from datetime import datetime
    from concurrent.futures import ThreadPoolExecutor

    fs = get_fs()

    print("fetching timestamp files to rename")

    # fetching may take 5 minutes or more, so we poll / log that we're waiting
    all_fnames = poll_task(
        lambda: fs.glob("gs://gtfs-data/rt/1*", use_listings_cache=False), 8 * 60
    )

    def move(entry):
        print("moving: %s" % str(entry))
        fs.mv(entry[0], entry[1], recursive=True)

    to_move = []

    for fname in all_fnames:
        timestamp = fname.split("/")[-1]

        dt = datetime.fromtimestamp(int(timestamp))

        fname_parent = "/".join(fname.split("/")[:-1])
        new_name = f"{fname_parent}/{dt.isoformat()}"

        # print("MOVING {fname} -> {new_name}")

        to_move.append((fname, new_name))

    print("\n\nNumber of files to move: %s\n\n" % len(to_move))

    print(to_move[:10])

    pool = ThreadPoolExecutor(8)
    list(pool.map(move, to_move))
