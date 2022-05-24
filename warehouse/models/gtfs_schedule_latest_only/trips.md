
{% docs gtfs_trips__route_id %}
Identifies a route.
{% enddocs %}

{% docs gtfs_trips__service_id %}
Identifies a set of dates when service is available for one or more routes.
{% enddocs %}

{% docs gtfs_trips__trip_id %}
Identifies a trip.
{% enddocs %}

{% docs gtfs_trips__trip_headsign %}
Text that appears on signage identifying the trip's destination to riders. Use this field to distinguish between different patterns of service on the same route. If the headsign changes during a trip, trip_headsign can be overridden by specifying values for the stop_times.stop_headsign.
{% enddocs %}

{% docs gtfs_trips__trip_short_name %}
Public facing text used to identify the trip to riders, for instance, to identify train numbers for commuter rail trips. If riders do not commonly rely on trip names, leave this field empty.  A trip_short_name value, if provided, should uniquely identify a trip within a service day; it should not be used for destination names or limited/express designations.
{% enddocs %}

{% docs gtfs_trips__direction_id %}
Indicates the direction of travel for a trip. This field is not used in routing; it provides a way to separate trips by direction when publishing time tables. Valid options are:

0 - Travel in one direction (e.g. outbound travel).
1 - Travel in the opposite direction (e.g. inbound travel).Example: The trip_headsign and direction_id fields could be used together to assign a name to travel in each direction for a set of trips. A trips.txt file could contain these records for use in time tables:
 trip_id,...,trip_headsign,direction_id
 1234,...,Airport,0
 1505,...,Downtown,1
{% enddocs %}

{% docs gtfs_trips__block_id %}
Identifies the block to which the trip belongs. A block consists of a single trip or many sequential trips made using the same vehicle, defined by shared service days and block_id. A block_id can have trips with different service days, making distinct blocks. See the example below
{% enddocs %}

{% docs gtfs_trips__shape_id %}
Identifies a geospatial shape describing the vehicle travel path for a trip.

Conditionally Required:
- Required if the trip has a continuous pickup or drop-off behavior defined either in routes.txt or in stop_times.txt.
- Optional otherwise.
{% enddocs %}

{% docs gtfs_trips__wheelchair_accessible %}
Indicates wheelchair accessibility. Valid options are:

0 or empty - No accessibility information for the trip.
1 - Vehicle being used on this particular trip can accommodate at least one rider in a wheelchair.
2 - No riders in wheelchairs can be accommodated on this trip.
{% enddocs %}

{% docs gtfs_trips__bikes_allowed %}
Indicates whether bikes are allowed. Valid options are:

0 or empty - No bike information for the trip.
1 - Vehicle being used on this particular trip can accommodate at least one bicycle.
2 - No bicycles are allowed on this trip.
{% enddocs %}
