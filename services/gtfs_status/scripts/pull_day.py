import setup  # noqa
from collections import defaultdict
from google.cloud import storage
import sys

from main.models import Bucket, BucketHour, Feed, FeedHour


def main(bucket_name, date_string):
    bucket, new = Bucket.objects.get_or_create(name=bucket_name)

    if new:
        print("Bucket created:", bucket)

    storage_client = storage.Client()
    for hour in range(24):
        times = set()
        times_by_key = defaultdict(list)
        for ten_m in range(6):
            prefix = f"rt/{date_string}T{hour:02.0f}:{ten_m}"
            print("on prefix:", prefix)
            blobs = storage_client.list_blobs(bucket.name, prefix=prefix)
            for blob in blobs:
                _, dt, itp_id, url_index, url_type = blob.name.split("/")
                date, time = dt.split("T")
                times.add(time)
                key = f"{itp_id}/{url_index}/{url_type}"
                times_by_key[key].append(time)
        bh, _ = BucketHour.objects.get_or_create(
            bucket=bucket, date=date_string, hour=hour,
        )
        bh.times = sorted(times)
        time_indexes = {time: index for index, time in enumerate(bh.times)}
        bh.save()
        for key, times in times_by_key.items():
            itp_id, url_index, url_type = key.split("/")
            feed, new = Feed.objects.get_or_create(
                itp_id=itp_id, url_index=url_index, url_type=url_type,
            )
            if new:
                print("new feed:", feed)
            files_at_times = [0] * len(bh.times)
            for time in times:
                files_at_times[time_indexes[time]] = 1
            feedhour, new = FeedHour.objects.get_or_create(
                buckethour=bh, feed=feed, files_at_times=files_at_times
            )


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
