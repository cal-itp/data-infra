{% docs fct_daily_schedule_feed_guideline_checks %}

Each row represents a date/guideline check/feed combination, with pass/fail
information indicating whether that feed complied with that check on that date.
A row will exist for every check, for every row from the index which is driven
by fct_daily_schedule_feeds. Only contains checks that are performed at the feed
level.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| No errors in MobilityData GTFS Schedule Validator | Compliance (Schedule) |GTFS Schedule Validator produced no errors for the transit provider’s static feed. |
| No shapes-related errors appear in the MobilityData GTFS Schedule Validator | Accurate Service Data | None of the following shapes-related errors appear in the MobilityData GTFS Schedule Validator: decreasing_shape_distance, equal_shape_distance_diff_coordinates, decreasing_or_equal_shape_distance, decreasing_or_equal_shape_distance. |
| Feed will be valid for more than 7 days | Best Practices Alignment (Schedule) | The MobilityData GTFS Validator warning, feed_expiration_date_7_days, does not appear for the given day. The warning description reads: "Dataset should be valid for at least the next 7 days." |
| Feed will be valid for more than 30 days | Best Practices Alignment (Schedule) | The MobilityData GTFS Validator warning, feed_expiration_date_30_days, does not appear for the given day. The warning description reads: "Dataset should cover at least the next 30 days of service." |
|Shapes.txt file is present | Accurate Service Data | Static GTFS feed contains the file shapes.txt.|
| Every trip in trips.txt has a shape_id listed | Accurate Service Data | Every trip in trips.txt has a shape_id listed. |
|Technical contact is listed in feed_contact_email field within the feed_info.txt file | Technical Contact Availability | The feed_contact_email field in feed_info.txt contains a non-empty value. |
| Include tts_stop_name entries in stops.txt for stop names that are pronounced incorrectly in most mobile applications. | Accurate Accessibility Data | For every stop_name in stops.txt containing text that is commonly mispronounced in trip planning applications, there is a non-null tts_stop_name field which is not identical to the stop_name field. The commonly mispronounced text includes directional abbreviations ("n","s","e","w","ne","se","sw","nw","nb","sb","eb","wb"), right-of-way names ("st","rd","blvd","hwy"), two or more adjacent numerals, and the symbols "/", "(" and ")". |
| Includes complete wheelchair accessibility data in both stops.txt and trips.txt | Accurate Accessibility Data | Trips.txt contains non-empty values for each trip in the wheelchair_accessible column, and stops.txt contains non-empty values for each stop in the wheelchair_boarding column. |
| No pathways-related errors appear in the MobilityData GTFS Validator | Accurate Accessibility Data| A transit provider is eligible for this check if they have at least one stop listed in stops.txt that: 1) Has "station" or "transit center" in the name, 2) Serves rail, or 3) Has a parent_station listed. For transit providers eligible for this check, they will pass if none of the following pathways-related notices appear in the GTFS Schedule Validator: pathway_to_platform_with_boarding_areas, pathway_to_wrong_location_type, pathway_unreachable_location, missing_level_id, station_with_parent_station, wrong_parent_location_type. |
| Passes Fares v2 portion of MobilityData GTFS Schedule Validator | Fare Completeness | For feeds containing at least one of the files: fare_leg_rules, rider_categories, fare_containers, fare_products, fare_transfer_rules, none of the following errors appear in the MobilityData GTFS Schedule Validator: fare_transfer_rule_duration_limit_type_without_duration_limit, fare_transfer_rule_duration_limit_without_type, fare_transfer_rule_invalid_transfer_count, fare_transfer_rule_missing_transfer_count, fare_transfer_rule_with_forbidden_transfer_count, invalid_currency_amount. |
| No expired services are listed in the feed | Best Practices Alignment (Schedule) | No service_id's exist in calendars.txt or calendar_dates.txt where the last in-effect date is in the past. |
| All schedule changes in the last month have provided at least 7 days of lead time | Up-to-Dateness | All changes made in the last 30 days to stops.txt, stop_times.txt, calendar.txt, and calendar_dates.txt did not impact trips within seven days of when the update was made. |
| Schedule feed maintains persistent identifiers for stop_id, route_id, and agency_id | Best Practices Alignment (Schedule)| In the last 30 days, no updates to the schedule feed have created a situation where 50% or more of a given ID (stop_id, route_id, agency_id) were not present in the previous feed version. |
| The GTFS Schedule API endpoint is configured to report the file modification date | Best Practices Alignment (Schedule) | When the GTFS Schedule API endpoint is requested, the response header includes a field called "Last-Modified". |

{% enddocs %}
