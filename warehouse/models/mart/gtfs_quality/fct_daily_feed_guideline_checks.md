{% docs fct_daily_feed_guideline_checks %}

Each row represents a date/guideline check/feed combination, with pass/fail
information indicating whether that feed complied with that check on that date.
A row will exist for every check, for every row from the index which is driven
by fct_daily_schedule_feeds. Only contains checks that are performed at the feed
level.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| No errors in MobilityData GTFS Schedule Validator |Compliance |GTFS Schedule Validator produced no errors for the transit provider’s static feed. |
|No shapes-related errors appear in the MobilityData GTFS Validator | Accurate Service Data | None of the following shapes-related errors appear in the GTFS Schedule Validator: decreasing_shape_distance, equal_shape_distance_diff_coordinates, decreasing_or_equal_shape_distance, decreasing_or_equal_shape_distance |
|Technical contact is listed in feed_contact_email field within the feed_info.txt file | Technical Contact Availability | The feed_contact_email field in feed_info.txt contains a non-empty value.|
|Includes complete wheelchair accessibility data in both stops.txt and trips.txt | Accurate Accessibility Data | Trips.txt contains non-empty values for each trip in the wheelchair_accessible column, and stops.txt contains non-empty values for each stop in the wheelchair_boarding column.|
{% enddocs %}
