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
| Feed will be valid for more than 7 days | Best Practices Alignment | The dataset expiration date defined in feed_info.txt is in 8 days or more |
| Feed will be valid for more than 30 days | Best Practices Alignment | The dataset expiration date defined in feed_info.txt is in 31 days or more |
|Shapes.txt file is present | Accurate Service Data | Static GTFS feed contains the file shapes.txt.|
| Every trip in trips.txt has a shape_id listed | Accurate Service Data | Every trip in trips.txt has a shape_id listed.|
|Technical contact is listed in feed_contact_email field within the feed_info.txt file | Technical Contact Availability | The feed_contact_email field in feed_info.txt contains a non-empty value.|
| Include tts_stop_name entries in stops.txt for stop names that are pronounced incorrectly in most mobile applications. | Accurate Accessibility Data | For every stop_name in stops.txt containing text that is commonly mispronounced in trip planning applications, there is a non-null tts_stop_name field which is not identical to the stop_name field. The commonly mispronounced text includes directional abbreviations ("n","s","e","w","ne","se","sw","nw","nb","sb","eb","wb"), right-of-way names ("st","rd","blvd","hwy"), two or more adjacent numerals, and the symbols "/", "(" and ")".|
|Includes complete wheelchair accessibility data in both stops.txt and trips.txt | Accurate Accessibility Data | Trips.txt contains non-empty values for each trip in the wheelchair_accessible column, and stops.txt contains non-empty values for each stop in the wheelchair_boarding column.|
| No pathways-related errors appear in the MobilityData GTFS Validator | Accurate Accessibility Data| A transit provider is eligible for this check if they have at least one stop listed in stops.txt that: 1) Has "station" or "transit center" in the name, 2) Serves rail, or 3) Has a parent_station listed. For transit providers eligible for this check, they will pass if none of the following pathways-related notices appear in the GTFS Schedule Validator: pathway_to_platform_with_boarding_areas, pathway_to_wrong_location_type, pathway_unreachable_location, missing_level_id, station_with_parent_station, wrong_parent_location_type. |
{% enddocs %}
