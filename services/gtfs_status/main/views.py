import datetime
from django.http import JsonResponse

from main.models import Bucket, Feed, FeedHour, BucketHour


def pick(o, keys):
    return {k: getattr(o, k) for k in keys}


def day_health(request, bucket_name=None):
    day = request.GET.get("day") or str(datetime.date.today())
    bucket = Bucket.objects.get(name=bucket_name)
    buckethours = BucketHour.objects.filter(date=day, bucket=bucket)
    feeds = Feed.objects.filter(bucket=bucket)
    feedhours = FeedHour.objects.filter(feed__in=feeds, buckethour__in=buckethours)

    def _todict(feed):
        return {"id": feed.id, "key": feed.key, "counts_by_hour": [0] * 24}

    feeds = {f.id: _todict(f) for f in feeds}
    for fh in feedhours:
        feeds[fh.feed_id]["counts_by_hour"][fh.hour] = sum(fh.files_at_times)
    return JsonResponse({"feeds": feeds})
