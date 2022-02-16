from django.db import models


def _choices(choices):
    return zip(choices, choices)


class Bucket(models.Model):
    name = models.CharField(max_length=255)

    def __str__(self):
        return self.name


class Feed(models.Model):
    bucket = models.ForeignKey(Bucket, models.CASCADE)
    itp_id = models.IntegerField()
    url_type = models.CharField(max_length=64)
    url_index = models.IntegerField()
    STATUS_CHOICES = _choices(["active", "disabled"])
    status = models.CharField(max_length=16, default="active", choices=STATUS_CHOICES,)

    def __str__(self):
        return self.key

    @property
    def key(self):
        id = self.itp_id
        index = self.url_index
        type = self.url_type
        return f"{id}/{index}/{type}"


class BucketHour(models.Model):
    bucket = models.ForeignKey(Bucket, models.CASCADE)
    date = models.DateField()
    hour = models.IntegerField()
    times = models.JSONField(
        default=list, help_text="A sorted list list of times that files were requested."
    )


class FeedHour(models.Model):
    feed = models.ForeignKey(Feed, models.CASCADE)
    buckethour = models.ForeignKey(BucketHour, models.CASCADE)
    files_at_times = models.JSONField(
        default=list, help_text="A list of 1s and 0s indicating if a file exists."
    )
