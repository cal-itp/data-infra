
{% docs gtfs_stop_times__trip_id %}
Identifies a trip.
{% enddocs %}

{% docs gtfs_stop_times__arrival_time %}
Arrival time at a specific stop for a specific trip on a route. If there are not separate times for arrival and departure at a stop, enter the same value for arrival_time and departure_time. For times occurring after midnight on the service day, enter the time as a value greater than 24:00:00 in HH:MM:SS local time for the day on which the trip schedule begins.

Scheduled stops where the vehicle strictly adheres to the specified arrival and departure times are timepoints. If this stop is not a timepoint, it is recommended to provide an estimated or interpolated time. If this is not available, arrival_time can be left empty. Further, indicate that interpolated times are provided with timepoint=0. If interpolated times are indicated with timepoint=0, then time points must be indicated with timepoint=1. Provide arrival times for all stops that are time points. An arrival time must be specified for the first and the last stop in a trip.
{% enddocs %}

{% docs gtfs_stop_times__departure_time %}
Departure time from a specific stop for a specific trip on a route. For times occurring after midnight on the service day, enter the time as a value greater than 24:00:00 in HH:MM:SS local time for the day on which the trip schedule begins. If there are not separate times for arrival and departure at a stop, enter the same value for arrival_time and departure_time. See the arrival_time description for more details about using timepoints correctly.

 The departure_time field should specify time values whenever possible, including non-binding estimated or interpolated times between timepoints.
{% enddocs %}

{% docs gtfs_stop_times__stop_id %}
Identifies the serviced stop. All stops serviced during a trip must have a record in stop_times.txt. Referenced locations must be stops, not stations or station entrances. A stop may be serviced multiple times in the same trip, and multiple trips and routes may service the same stop.
{% enddocs %}

{% docs gtfs_stop_times__stop_sequence %}
Order of stops for a particular trip. The values must increase along the trip but do not need to be consecutive.Example: The first location on the trip could have a stop_sequence=1, the second location on the trip could have a stop_sequence=23, the third location could have a stop_sequence=40, and so on.
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
{% enddocs %}

{% docs gtfs_stop_times__drop_off_type %}
Indicates drop off method. Valid options are:

0 or empty - Regularly scheduled drop off.
1 - No drop off available.
2 - Must phone agency to arrange drop off.
3 - Must coordinate with driver to arrange drop off.
{% enddocs %}

{% docs gtfs_stop_times__continuous_pickup %}
Indicates that the rider can board the transit vehicle at any point along the vehicle’s travel path as described by shapes.txt, from this stop_time to the next stop_time in the trip’s stop_sequence. Valid options are:

0 - Continuous stopping pickup.
1 or empty - No continuous stopping pickup.
2 - Must phone agency to arrange continuous stopping pickup.
3 - Must coordinate with driver to arrange continuous stopping pickup.

If this field is populated, it overrides any continuous pickup behavior defined in routes.txt. If this field is empty, the stop_time inherits any continuous pickup behavior defined in routes.txt.
{% enddocs %}

{% docs gtfs_stop_times__continuous_drop_off %}
Indicates that the rider can alight from the transit vehicle at any point along the vehicle’s travel path as described by shapes.txt, from this stop_time to the next stop_time in the trip’s stop_sequence. Valid options are:

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
