Original definitions from https://gtfs.org/realtime/reference/#message-tripupdate

{% docs rt_trip_update__timestamp %}
The most recent moment at which the vehicle's real-time progress was measured to estimate StopTimes in the future. When StopTimes in the past are provided, arrival/departure times may be earlier than this value. In POSIX time (i.e., the number of seconds since January 1st 1970 00:00:00 UTC).
{% enddocs %}

{% docs rt_trip_update__delay %}
The current schedule deviation for the trip. Delay should only be specified when the prediction is given relative to some existing schedule in GTFS.
Delay (in seconds) can be positive (meaning that the vehicle is late) or negative (meaning that the vehicle is ahead of schedule). Delay of 0 means that the vehicle is exactly on time.
Delay information in StopTimeUpdates take precedent of trip-level delay information, such that trip-level delay is only propagated until the next stop along the trip with a StopTimeUpdate delay value specified.
Feed providers are strongly encouraged to provide a TripUpdate.timestamp value indicating when the delay value was last updated, in order to evaluate the freshness of the data.
Caution: this field is still experimental, and subject to change. It may be formally adopted in the future.
{% enddocs %}
