Original definitions from https://gtfs.org/reference/static#stop_timestxt

{% docs gtfs_stop_times__trip_id %}
Identifies a trip.
{% enddocs %}

Note 5/17/23: Arrival and departure time docs are a mashup of the current content on gtfs.org and the Flex docs from https://github.com/MobilityData/gtfs-flex/blob/master/spec/reference.md
{% docs gtfs_stop_times__arrival_time %}
Arrival time at the stop (defined by stop_times.stop_id) for a specific trip (defined by stop_times.trip_id).

If there are not separate times for arrival and departure at a stop, arrival_time and departure_time should be the same.

For times occurring after midnight on the service day, enter the time as a value greater than 24:00:00 in HH:MM:SS local time for the day on which the trip schedule begins.

If exact arrival and departure times (timepoint=1 or empty) are not available, estimated or interpolated arrival and departure times (timepoint=0) should be provided.

Conditionally Required:
- Required for the first and the last stop in a trip.
- Required for timepoint=1.
- Forbidden when stop_times.start_pickup_drop_off_window or stop_times.end_pickup_drop_off_window are defined.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_stop_times__departure_time %}
Departure time from the stop (defined by stop_times.stop_id) for a specific trip (defined by stop_times.trip_id).

If there are not separate times for arrival and departure at a stop, arrival_time and departure_time should be the same.

For times occurring after midnight on the service day, enter the time as a value greater than 24:00:00 in HH:MM:SS local time for the day on which the trip schedule begins.

If exact arrival and departure times (timepoint=1 or empty) are not available, estimated or interpolated arrival and departure times (timepoint=0) should be provided.

Conditionally required:
- Required for timepoint=1.
- Forbidden when stop_times.start_pickup_drop_off_window or stop_times.end_pickup_drop_off_window are defined.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_stop_times__stop_id %}
Identifies the serviced stop. All stops serviced during a trip must have a record in stop_times.txt. Referenced locations must be stops, not stations or station entrances. A stop may be serviced multiple times in the same trip, and multiple trips and routes may service the same stop.

If service is on demand, a GeoJSON location or stop area can be referenced:
- id from locations.geojson
- stop_areas.area_id
{% enddocs %}

{% docs gtfs_stop_times__stop_sequence %}
Order of stops for a particular trip. The values must increase along the trip but do not need to be consecutive.

Example: The first location on the trip could have a stop_sequence=1, the second location on the trip could have a stop_sequence=23, the third location could have a stop_sequence=40, and so on.

Travel within the same stop area or GeoJSON location requires two records in stop_times.txt with the same stop_id and consecutive values of stop_sequence.
{% enddocs %}

{% docs gtfs_stop_times__stop_headsign %}
Text that appears on signage identifying the trip's destination to riders. This field overrides the default trips.trip_headsign when the headsign changes between stops. If the headsign is displayed for an entire trip, use trips.trip_headsign instead.

  A stop_headsign value specified for one stop_time does not apply to subsequent stop_times in the same trip. If you want to override the trip_headsign for multiple stop_times in the same trip, the stop_headsign value must be repeated in each stop_time row.
{% enddocs %}

{% docs gtfs_stop_times__pickup_type %}
Indicates pickup method. Valid options are:

0 or empty - Regularly scheduled pickup.
1 - No pickup available.
2 - Must phone agency to arrange pickup.
3 - Must coordinate with driver to arrange pickup.

Conditionally Forbidden:
- pickup_type=0 forbidden for stop_times.stop_id referring to stop_areas.area_id or id from locations.geojson.
- pickup_type=3 forbidden for stop_areas.area_id or locations.geojson.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_stop_times__drop_off_type %}
Indicates drop off method. Valid options are:

0 or empty - Regularly scheduled drop off.
1 - No drop off available.
2 - Must phone agency to arrange drop off.
3 - Must coordinate with driver to arrange drop off.

Conditionally Forbidden:
- drop_off_type=0 forbidden for stop_times.stop_id referring to stop_areas.area_id or id from locations.geojson.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_stop_times__continuous_pickup %}
Indicates that the rider can board the transit vehicle at any point along the vehicle's travel path as described by shapes.txt, from this stop_time to the next stop_time in the trip's stop_sequence. Valid options are:

0 - Continuous stopping pickup.
1 or empty - No continuous stopping pickup.
2 - Must phone agency to arrange continuous stopping pickup.
3 - Must coordinate with driver to arrange continuous stopping pickup.

If this field is populated, it overrides any continuous pickup behavior defined in routes.txt. If this field is empty, the stop_time inherits any continuous pickup behavior defined in routes.txt.
{% enddocs %}

{% docs gtfs_stop_times__continuous_drop_off %}
Indicates that the rider can alight from the transit vehicle at any point along the vehicle's travel path as described by shapes.txt, from this stop_time to the next stop_time in the trip's stop_sequence. Valid options are:

0 - Continuous stopping drop off.
1 or empty - No continuous stopping drop off.
2 - Must phone agency to arrange continuous stopping drop off.
3 - Must coordinate with driver to arrange continuous stopping drop off.

If this field is populated, it overrides any continuous drop-off behavior defined in routes.txt. If this field is empty, the stop_time inherits any continuous drop-off behavior defined in routes.txt.
{% enddocs %}

{% docs gtfs_stop_times__shape_dist_traveled %}
Actual distance traveled along the associated shape, from the first stop to the stop specified in this record. This field specifies how much of the shape to draw between any two stops during a trip. Must be in the same units used in shapes.txt. Values used for shape_dist_traveled must increase along with stop_sequence; they cannot be used to show reverse travel along a route.Example: If a bus travels a distance of 5.25 kilometers from the start of the shape to the stop,shape_dist_traveled=5.25.
{% enddocs %}

{% docs gtfs_stop_times__timepoint %}
Indicates if arrival and departure times for a stop are strictly adhered to by the vehicle or if they are instead approximate and/or interpolated times. This field allows a GTFS producer to provide interpolated stop-times, while indicating that the times are approximate. Valid options are:

0 - Times are considered approximate.
1 or empty - Times are considered exact.
{% enddocs %}

{% docs gtfs_stop_times__start_pickup_drop_off_window %}
Time that on-demand service becomes available in a GeoJSON location, stop area or stop.

Conditionally Required:
- Required if stop_times.stop_id refers to stop_areas.area_id or id from locations.geojson.
- Forbidden if stop_times.arrival_time or stop_times.departure_time are defined.
{% enddocs %}

{% docs gtfs_stop_times__end_pickup_drop_off_window %}
Time that on-demand service ends in a GeoJSON location, stop area or stop.

Conditionally Required:
- Required if stop_times.stop_id refers to stop_areas.area_id or id from locations.geojson.
- Forbidden if stop_times.arrival_time or stop_times.departure_time are defined.
{% enddocs %}

{% docs gtfs_stop_times__mean_duration_factor %}
Together, mean_duration_factor and mean_duration_offset allow an estimation of the duration a rider’s trip will take, in minutes, using the on-demand service in a GeoJSON location or stop area.

Data consumers are expected to use mean_duration_factor and mean_duration_offset to make the following calculation: MeanTravelDuration = mean_duration_factor × DrivingDuration + mean_duration_offset where DrivingDuration is the time it would take in a car to travel the distance being calculated for the on-demand service, and MeanTravelDuration is the calculated average time one expects to travel the same trip using the on-demand service.

See https://github.com/MobilityData/gtfs-flex/blob/master/spec/reference.md for full details.

While traveling through undefined space between GeoJSON locations or stop areas, it is assumed that: MeanTravelDuration = DrivingDuration

Conditionally Forbidden:
- Forbidden if stop_times.stop_id does not refer to a stop_areas.area_id or an id from locations.geojson.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_stop_times__mean_duration_offset %}
Together, mean_duration_factor and mean_duration_offset allow an estimation of the duration a rider’s trip will take, in minutes, using the on-demand service in a GeoJSON location or stop area.

Data consumers are expected to use mean_duration_factor and mean_duration_offset to make the following calculation: MeanTravelDuration = mean_duration_factor × DrivingDuration + mean_duration_offset where DrivingDuration is the time it would take in a car to travel the distance being calculated for the on-demand service, and MeanTravelDuration is the calculated average time one expects to travel the same trip using the on-demand service.

See https://github.com/MobilityData/gtfs-flex/blob/master/spec/reference.md for full details.

While traveling through undefined space between GeoJSON locations or stop areas, it is assumed that: MeanTravelDuration = DrivingDuration

Conditionally Forbidden:
- Forbidden if stop_times.stop_id does not refer to a stop_areas.area_id or an id from locations.geojson.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_stop_times__safe_duration_factor %}
Together, safe_duration_factor and safe_duration_offset allow an estimation of the longest amount of time a rider can expect the on-demand service in a GeoJSON location or stop areas may require, in minutes, for 95% of trips.

Data consumers are expected to use safe_duration_factor and safe_duration_offset to make the following calculation:

SafeTravelDuration = safe_duration_factor × DrivingDuration + safe_duration_offset

Where DrivingDuration is the time it would take in a car to travel the distance being calculated for the on-demand service, and SafeTravelDuration is the longest amount of time a rider can expect the on-demand service in a GeoJSON location or stop area may require.

Conditionally Forbidden:
- Forbidden if stop_times.stop_id does not refer to a stop_areas.area_id or an id from locations.geojson.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_stop_times__safe_duration_offset %}
Together, safe_duration_factor and safe_duration_offset allow an estimation of the longest amount of time a rider can expect the on-demand service in a GeoJSON location or stop areas may require, in minutes, for 95% of trips.

Data consumers are expected to use safe_duration_factor and safe_duration_offset to make the following calculation:

SafeTravelDuration = safe_duration_factor × DrivingDuration + safe_duration_offset

Where DrivingDuration is the time it would take in a car to travel the distance being calculated for the on-demand service, and SafeTravelDuration is the longest amount of time a rider can expect the on-demand service in a GeoJSON location or stop area may require.

Conditionally Forbidden:
- Forbidden if stop_times.stop_id does not refer to a stop_areas.area_id or an id from locations.geojson.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_stop_times__pickup_booking_rule_id %}
Identifies the boarding booking rule at this stop time.

Recommended when pickup_type=2.
{% enddocs %}

{% docs gtfs_stop_times__drop_off_booking_rule_id %}
Identifies the alighting booking rule at this stop time.

Recommended when drop_off_type=2.
{% enddocs %}
