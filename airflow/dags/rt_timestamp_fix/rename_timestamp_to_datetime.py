# ---
# python_callable: main
# ---

# Note that gusty seems to require a top level function, due to how it exec's tasks
# see https://github.com/chriscardillo/gusty/issues/33


def main():
    from calitp.storage import get_fs
    from datetime import datetime
    from concurrent.futures import ThreadPoolExecutor

    fs = get_fs()

    all_fnames = fs.glob("gs://gtfs-data/rt/1*")

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
