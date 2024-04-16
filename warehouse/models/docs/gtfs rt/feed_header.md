Original definitions from https://gtfs.org/realtime/reference/#message-feedheader.

{% docs rt_feed_header__timestamp %}
This timestamp identifies the moment when the content of this feed has been created (in server time). In POSIX time (i.e., number of seconds since January 1st 1970 00:00:00 UTC). To avoid time skew between systems producing and consuming realtime information it is strongly advised to derive timestamp from a time server. It is completely acceptable to use Stratum 3 or even lower strata servers since time differences up to a couple of seconds are tolerable.
Field has been converted to TIMESTAMP type for convenience.
{% enddocs %}

{% docs rt_feed_header__incrementality %}
Determines whether the current fetch is incremental.
FULL_DATASET: this feed update will overwrite all preceding realtime information for the feed. Thus this update is expected to provide a full snapshot of all known realtime information.
DIFFERENTIAL: currently, this mode is unsupported and behavior is unspecified for feeds that use this mode. There are discussions on the GTFS Realtime mailing list around fully specifying the behavior of DIFFERENTIAL mode and the documentation will be updated when those discussions are finalized.
{% enddocs %}

{% docs rt_feed_header__version %}
Version of the feed specification. The current version is 2.0.
{% enddocs %}
