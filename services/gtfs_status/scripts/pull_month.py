import datetime
import setup  # noqa
from pull_day import pull_day
import sys

from main.models import Bucket, BucketHour


def pull_month(bucket_name, month):
    year, month = [int(i) for i in month.split("-")]
    day = 1
    bucket = Bucket.objects.get(name=bucket_name)
    while True:
        try:
            date = datetime.date(year, month, day)
        except ValueError:
            break
        if BucketHour.objects.filter(bucket=bucket, date=date).count() != 24:
            pull_day(bucket_name, str(date))
        day += 1


if __name__ == "__main__":
    pull_month(sys.argv[1], sys.argv[2])
