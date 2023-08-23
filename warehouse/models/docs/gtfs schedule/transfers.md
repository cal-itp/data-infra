Original definitions from https://gtfs.org/reference/static#transferstxt

{% docs gtfs_transfers__from_stop_id %}
Identifies a stop or station where a connection between routes begins. If this field refers to a station, the transfer rule applies to all its child stops.
{% enddocs %}

{% docs gtfs_transfers__to_stop_id %}
Identifies a stop or station where a connection between routes ends. If this field refers to a station, the transfer rule applies to all child stops.
{% enddocs %}

{% docs gtfs_transfers__transfer_type %}
Indicates the type of connection for the specified (from_stop_id, to_stop_id) pair. Valid options are:

 0 or empty - Recommended transfer point between routes.
1 - Timed transfer point between two routes. The departing vehicle is expected to wait for the arriving one and leave sufficient time for a rider to transfer between routes.
2 - Transfer requires a minimum amount of time between arrival and departure to ensure a connection. The time required to transfer is specified by min_transfer_time.
3 - Transfers are not possible between routes at the location.
{% enddocs %}

{% docs gtfs_transfers__min_transfer_time %}
Amount of time, in seconds, that must be available to permit a transfer between routes at the specified stops. The min_transfer_time should be sufficient to permit a typical rider to move between the two stops, including buffer time to allow for schedule variance on each route.
{% enddocs %}

{% docs gtfs_transfers__from_route_id %}
Identifies a route where a connection begins. If from_route_id is defined, the transfer will apply to the arriving trip on the route for the given from_stop_id. If both from_trip_id and from_route_id are defined, the trip_id must belong to the route_id, and from_trip_id will take precedence.
{% enddocs %}

{% docs gtfs_transfers__to_route_id %}
Identifies a route where a connection ends. If to_route_id is defined, the transfer will apply to the departing trip on the route for the given to_stop_id. If both to_trip_id and to_route_id are defined, the trip_id must belong to the route_id, and to_trip_id will take precedence.
{% enddocs %}

{% docs gtfs_transfers__from_trip_id %}
Identifies a trip where a connection between routes begins. If from_trip_id is defined, the transfer will apply to the arriving trip for the given from_stop_id. If both from_trip_id and from_route_id are defined, the trip_id must belong to the route_id, and from_trip_id will take precedence. REQUIRED if transfer_type is 4 or 5.
{% enddocs %}

{% docs gtfs_transfers__to_trip_id %}
Identifies a trip where a connection between routes ends. If to_trip_id is defined, the transfer will apply to the departing trip for the given to_stop_id. If both to_trip_id and to_route_id are defined, the trip_id must belong to the route_id, and to_trip_id will take precedence. REQUIRED if transfer_type is 4 or 5.
{% enddocs %}
