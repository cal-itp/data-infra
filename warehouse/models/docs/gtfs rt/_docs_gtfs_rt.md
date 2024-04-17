Docs macros that apply to GTFS realtime data only

{% docs column_header_message_age %}
Difference between `_extract_ts` (time at which we scraped the message) and
`header_timestamp` (timestamp of overall message from producer; see
https://gtfs.org/realtime/reference/#message-feedheader).
Because of delay in the request process, the actual scrape request may occur
up to a few seconds after `_extract_ts`, and it may take time for the producer to respond to the request, so this field should only be interpreted as accurate within 3-4 seconds (do not try to do extremely precise measurements below that level.)
{% enddocs %}

{% docs column_trip_update_message_age %}
Difference between `_extract_ts` (time at which we scraped the message) and `trip_update_timestamp` (timestamp of individual trip update message from producer; see https://gtfs.org/realtime/reference/#message-tripupdate).
Because of delay in the request process, the actual scrape request may occur up to a few seconds after `_extract_ts`, and it may take time for the producer to respond to the request, so this field should only be interpreted as accurate within 3-4 seconds (do not try to do extremely precise measurements below that level.)
{% enddocs %}

{% docs column_trip_update_message_age_vs_header %}
Difference between `header_timestamp` (timestamp of overall message from producer; see https://gtfs.org/realtime/reference/#message-feedheader) and `trip_update_timestamp` (timestamp of individual trip_update message from producer; see https://gtfs.org/realtime/reference/#message-tripupdate).
{% enddocs %}

{% docs column_vehicle_message_age %}
Difference in seconds between `_extract_ts` (time at which we scraped the message) and `vehicle_timestamp` (timestamp of individual vehicle message from producer; see https://gtfs.org/realtime/reference/#message-vehicleposition).
Because of delay in the request process, the actual scrape request may occur up to a few seconds after `_extract_ts`, and it may take time for the producer to respond to the request, so this field should only be interpreted as accurate within 3-4 seconds (do not try to do extremely precise measurements below that level.)
{% enddocs %}

{% docs column_vehicle_message_age_vs_header %}
Difference in seconds between `header_timestamp` (timestamp of overall message from producer; see https://gtfs.org/realtime/reference/#message-feedheader) and `vehicle_timestamp` (timestamp of individual vehicle message from producer; see https://gtfs.org/realtime/reference/#message-vehicleposition).
{% enddocs %}

{% docs rt_feed_type %}
One of `service_alerts`, `vehicle_positions`, and `trip_updates`.
{% enddocs %}

{% docs column_rt_extract_ts %}
Timestamp at which this message was scraped. More specifically, this identifies the individual "tick" for which this data was collected. These value are pinned to `:00`, `:20`, `:40` second values (to ensure consistency), but there can be some slippage between the `_extract_ts` and the time that the data was actually requested.
{% enddocs %}

{% docs column_rt_config_extract_ts %}
The timestamp at which the GTFS data config for this download was extracted. This will correspond to the `ts` value for the associated Airtable data extract.
Note that there may not be a corresponding value in `dim_gtfs_datasets` with this value in `_valid_from`, because this value updates every time that the Airtable data extract runs, whereas `dim_gtfs_datasets` has versioning applied and `_valid_from` only updates when an attribute within the record actually changes.
{% enddocs %}
