Original definitions from https://gtfs.org/realtime/reference/#message-stoptimeevent

{% docs gtfs_stop_time_event__delay %}
Delay (in seconds) can be positive (meaning that the vehicle is late) or negative (meaning that the vehicle is ahead of schedule). Delay of 0 means that the vehicle is exactly on time. Either delay or time must be provided within a StopTimeEvent - both fields cannot be empty.
{% enddocs %}

{% docs gtfs_stop_time_event__time %}
Event as absolute time. In POSIX time (i.e., number of seconds since January 1st 1970 00:00:00 UTC). Either delay or time must be provided within a StopTimeEvent - both fields cannot be empty.
{% enddocs %}

{% docs gtfs_stop_time_event__uncertainty %}
If uncertainty is omitted, it is interpreted as unknown. To specify a completely certain prediction, set its uncertainty to 0.
{% enddocs %}
