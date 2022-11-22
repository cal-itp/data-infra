{% docs fct_daily_rt_feed_guideline_checks %}

Each row represents a date/guideline check/feed combination, with pass/fail
information indicating whether that feed complied with that check on that date.
A row will exist for every check, for every row from the index which is driven
by fct_daily_rt_feeds. Only contains checks that are performed at the feed
level.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
|No critical errors in the MobilityData GTFS Realtime Validator | Compliance | The feed has at least one GTFS-RT file present on the given day, and GTFS Realtime Validator produced no critical errors for any RT feed extract on that day.|
|Vehicle positions RT feed is present | Compliance | The vehicle positions RT file is present at least once on the given day.|
| Trip updates RT feed is present | Compliance | The trip updates RT file is present at least once on the given day.|
| Service alerts RT feed is present | Compliance | The service alerts RT file is present at least once on the given day.|
{% enddocs %}
