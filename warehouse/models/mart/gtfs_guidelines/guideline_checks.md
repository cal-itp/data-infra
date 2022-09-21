{% docs guideline_checks %}


Each row represents a date/guideline check/feed combination, with pass/fail information indicating whether that feed complied with that check on that date.

Here is a list of currently-implemented checks:

| Check | Feature | Description |
| ------------------------------------ |---------|------------ |
| No errors in MobilityData GTFS Schedule Validator |Compliance |GTFS Schedule Validator produced no errors for the transit provider’s static feed. |
| Static GTFS feed downloads successfully | Compliance | The static GTFS feed was able to be successfully downloaded.|
|Includes complete wheelchair accessibility data in both stops.txt and trips.txt | Accurate Accessibility Data | Trips.txt contains non-empty values for each trip in the wheelchair_accessible column, and stops.txt contains non-empty values for each stop in the wheelchair_boarding column.|
|Technical contact is listed in feed_contact_email field within the feed_info.txt file | Technical Contact Availability | The feed_contact_email field in feed_info.txt contains a non-empty value.|
|Shapes.txt file is present | Accurate Service Data | Static GTFS feed contains the file shapes.txt. |
|No shapes-related notices appear in the MobilityData GTFS Validator | Accurate Service Data | None of the following shapes-related notices appear in the GTFS Schedule Validator: decreasing_shape_distance, equal_shape_distance_diff_coordinates, decreasing_or_equal_shape_distance, equal_shape_distance_same_coordinates, stops_match_shape_out_of_order, stop_too_far_from_shape, stop_too_far_from_shape_using_user_distance, stop_too_far_from_trip_shape, decreasing_or_equal_shape_distance |
| No pathways-related notices appear in the MobilityData GTFS Validator | Accurate Accessibility Data| None of the following pathways-related notices appear in the GTFS Schedule Validator: pathway_to_platform_with_boarding_areas, pathway_to_wrong_location_type, pathway_unreachable_location, missing_level_id, station_with_parent_station, wrong_parent_location_type, pathway_dangling_generic_node, pathway_loop, platform_without_parent_station |
|No critical errors in the MobilityData GTFS Realtime Validator | Compliance | The feed has at least one GTFS-RT file present on the given day, and GTFS Realtime Validator produced no critical errors for any RT feed on that day.|
|All trip_ids provided in the GTFS-rt feed exist in the GTFS data | Fixed-Route Completeness | The feed has at least one GTFS-RT file present on the given day, and the MobilityData GTFS Realtime Validator did not produce error E003, “All trip_ids provided in the GTFS-rt feed must exist in the GTFS data, unless the schedule_relationship is ADDED”.|
|Vehicle positions RT feed is present | Compliance | The vehicle positions RT file is present at least once on the given day.|
| Trip updates RT feed is present | Compliance | The trip updates RT file is present at least once on the given day.|
| Service alerts RT feed is present | Compliance | The service alerts RT file is present at least once on the given day.|
| GTFS schedule feed is listed on feed aggregator transit.land | Feed Aggregator Availability | GTFS schedule feed is listed on feed aggregator transit.land on the given day. Due to current limitations, this check will be less reliable for agencies with multiple schedule feeds listed in agencies.yml. If one of the feeds listed is on transit.land, it will pass for all schedule feeds. |
| Vehicle positions RT feed is listed on feed aggregator transit.land | Feed Aggregator Availability | Vehicle positions RT feed is listed on feed aggregator transit.land on the given day. Due to current limitations, this check will be less reliable for agencies with multiple vehicle positions feeds listed in agencies.yml. If one of the feeds listed is on transit.land, it will pass for all vehicle positions feeds. |
| Trip updates RT feed is listed on feed aggregator transit.land | Feed Aggregator Availability | Trip updates RT feed is listed on feed aggregator transit.land on the given day. Due to current limitations, this check will be less reliable for agencies with multiple trip updates feeds listed in agencies.yml. If one of the feeds listed is on transit.land, it will pass for all trip updates feeds. |
| Service alerts RT feed is listed on feed aggregator transit.land | Feed Aggregator Availability | Service alerts RT feed is listed on feed aggregator transit.land on the given day. Due to current limitations, this check will be less reliable for agencies with multiple service alerts feeds listed in agencies.yml. If one of the service alerts feeds listed is on transit.land, it will pass for all feeds. |
{% enddocs %}
