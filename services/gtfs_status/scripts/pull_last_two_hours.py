import datetime
import setup  # noqa
from pull_day import pull_day
import sys


def pull_last_two_hours(bucket_name):
    current_utc = datetime.datetime.utcnow()
    pull_day(bucket_name, str(current_utc.date()), hours=[current_utc.hour])
    last_utc = current_utc + datetime.timedelta(-3600)
    pull_day(bucket_name, str(last_utc.date()), hours=[last_utc.hour])


if __name__ == "__main__":
    pull_last_two_hours(sys.argv[1])
