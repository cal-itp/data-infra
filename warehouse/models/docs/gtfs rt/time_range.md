Original definitions from https://gtfs.org/realtime/reference/#message-timerange

{% docs rt_time_range__start %}
Start time, in POSIX time (i.e., number of seconds since January 1st 1970 00:00:00 UTC). If missing, the interval starts at minus infinity. If a TimeRange is provided, either start or end must be provided - both fields cannot be empty.
{% enddocs %}

{% docs rt_time_range__end %}
End time, in POSIX time (i.e., number of seconds since January 1st 1970 00:00:00 UTC). If missing, the interval ends at plus infinity. If a TimeRange is provided, either start or end must be provided - both fields cannot be empty.
{% enddocs %}
