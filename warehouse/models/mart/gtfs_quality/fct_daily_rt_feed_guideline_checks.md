{% docs fct_daily_rt_feed_guideline_checks %}

Each row represents a date/guideline check/feed combination, with pass/fail
information indicating whether that feed complied with that check on that date.
A row will exist for every check, for every row from the index which is driven
by fct_daily_rt_feeds. Only contains checks that are performed at the feed
level.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
|No critical errors in the MobilityData GTFS Realtime Validator | Compliance (RT) | The feed has at least one GTFS-RT file present on the given day, and GTFS Realtime Validator produced no critical errors for any RT feed extract on that day.|
|All trip_ids provided in the GTFS-rt feed exist in the GTFS Schedule feed| Fixed-Route Completeness | Error code E003 does not appear in the MobilityData GTFS Realtime Validator on that day.|
|Vehicle positions RT feed is present | Compliance (RT) | The vehicle positions RT feed contains at least one file on the given day.|
| Trip updates RT feed is present | Compliance (RT) | The trip updates RT feed contains at least one file on the given day.|
| Service alerts RT feed is present | Compliance (RT) | The service alerts RT feed contains at least one file on the given day.|
| Service alerts RT feed uses HTTPS | Best Practice Alignment (RT) | The service alerts RT feed endpoint uses HTTPS instead of HTTPS to ensure feed integrity.|
|Vehicle positions RT feed uses HTTPS | Best Practice Alignment (RT) | The vehicle positions RT feed endpoint uses HTTPS instead of HTTPS to ensure feed integrity.|
| Trip updates RT feed uses HTTPS | Best Practice Alignment (RT) | The trip updates RT feed endpoint uses HTTPS instead of HTTPS to ensure feed integrity.|
| Fewer than 1% of requests to Trip updates RT feed result in a protobuf error | Best Practice Alignment (RT) | On the given day, fewer than 1% of Trip updates RT feed downloads result in a protobuf error.|
| Fewer than 1% of requests to Service alerts RT feed result in a protobuf error | Best Practice Alignment (RT) | On the given day, fewer than 1% of Service alerts RT feed downloads result in a protobuf error.|
| Fewer than 1% of requests to Vehicle positions RT feed result in a protobuf error | Best Practice Alignment (RT) | On the given day, fewer than 1% of Vehicle positions RT feed downloads result in a protobuf error.|
| Vehicle positions RT feed contains no updates older than 90 seconds. | Best Practices Alignment (RT) | At no point during the day is there a Vehicle positions file that is older than 90 seconds. |
| Trip updates RT feed contains no updates older than 90 seconds. | Best Practices Alignment (RT) | At no point during the day is there a Trip updates file that is older than 90 seconds. |
| Service alerts RT feed contains no updates older than 10 minutes. | Best Practices Alignment (RT) | At no point during the day is there a Service alerts file that is older than 10 minutes. |
{% enddocs %}
