Original definitions from https://gtfs.org/realtime/reference/#message-stoptimeupdate

{% docs gtfs_stop_time_update__timestamp %}
The most recent moment at which the vehicle's real-time progress was measured to estimate StopTimes in the future. When StopTimes in the past are provided, arrival/departure times may be earlier than this value. In POSIX time (i.e., the number of seconds since January 1st 1970 00:00:00 UTC).
{% enddocs %}
