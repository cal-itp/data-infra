from django.contrib import admin
from main.models import Bucket, Feed, BucketHour


@admin.register(Bucket)
class BucketAdmin(admin.ModelAdmin):
    pass


@admin.register(BucketHour)
class BucketHourAdmin(admin.ModelAdmin):
    pass


@admin.register(Feed)
class FeedAdmin(admin.ModelAdmin):
    pass
