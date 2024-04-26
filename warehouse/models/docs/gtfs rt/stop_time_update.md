Original definitions from https://gtfs.org/realtime/reference/#message-stoptimeupdate

{% docs gtfs_stop_time_update__stop_sequence %}
Must be the same as in stop_times.txt in the corresponding GTFS feed. Either stop_sequence or stop_id must be provided within a StopTimeUpdate - both fields cannot be empty. stop_sequence is required for trips that visit the same stop_id more than once (e.g., a loop) to disambiguate which stop the prediction is for. If StopTimeProperties.assigned_stop_id is populated, then stop_sequence must be populated.
{% enddocs %}

{% docs gtfs_stop_time_update__stop_id %}
Must be the same as in stops.txt in the corresponding GTFS feed. Either stop_sequence or stop_id must be provided within a StopTimeUpdate - both fields cannot be empty. If StopTimeProperties.assigned_stop_id is populated, it is preferred to omit stop_id and use only stop_sequence. If StopTimeProperties.assigned_stop_id and stop_id are populated, stop_id must match assigned_stop_id.
{% enddocs %}

{% docs gtfs_stop_time_update__arrival %}
If schedule_relationship is empty or SCHEDULED, either arrival or departure must be provided within a StopTimeUpdate - both fields cannot be empty. arrival and departure may both be empty when schedule_relationship is SKIPPED. If schedule_relationship is NO_DATA, arrival and departure must be empty.
{% enddocs %}

{% docs gtfs_stop_time_update__departure %}
If schedule_relationship is empty or SCHEDULED, either arrival or departure must be provided within a StopTimeUpdate - both fields cannot be empty. arrival and departure may both be empty when schedule_relationship is SKIPPED. If schedule_relationship is NO_DATA, arrival and departure must be empty.
{% enddocs %}

{% docs gtfs_stop_time_update__departure_occupancy_status %}
The predicted state of passenger occupancy for the vehicle immediately after departure from the given stop. If provided, stop_sequence must be provided. To provide departure_occupancy_status without providing any real-time arrival or departure predictions, populate this field and set StopTimeUpdate.schedule_relationship = NO_DATA.

Caution: this field is still experimental, and subject to change. It may be formally adopted in the future.
{% enddocs %}

{% docs gtfs_stop_time_update__schedule_relationship %}
The default relationship is SCHEDULED.
{% enddocs %}


{% docs gtfs_stop_time_update__stop_time_properties %}
Realtime updates for certain properties defined within GTFS stop_times.txt

Caution: this field is still experimental, and subject to change. It may be formally adopted in the future.{% enddocs %}
