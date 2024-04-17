Original definitions from https://gtfs.org/realtime/reference/#message-position

{% docs gtfs_position__latitude %}
Degrees North, in the WGS-84 coordinate system.
{% enddocs %}

{% docs gtfs_position__longitude %}
Degrees East, in the WGS-84 coordinate system.
{% enddocs %}

{% docs gtfs_position__bearing %}
Bearing, in degrees, clockwise from True North, i.e., 0 is North and 90 is East. This can be the compass bearing, or the direction towards the next stop or intermediate location. This should not be deduced from the sequence of previous positions, which clients can compute from previous data.
{% enddocs %}

{% docs gtfs_position__odometer %}
Odometer value, in meters.
{% enddocs %}

{% docs gtfs_position__speed %}
Momentary speed measured by the vehicle, in meters per second.
{% enddocs %}
