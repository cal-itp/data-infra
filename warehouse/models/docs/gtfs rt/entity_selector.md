Original definitions from https://gtfs.org/realtime/reference/#message-entityselector

{% docs rt_entity_selector__agency_id %}
The agency_id from the GTFS feed that this selector refers to.
{% enddocs %}

{% docs rt_entity_selector__route_id %}
The route_id from the GTFS that this selector refers to. If direction_id is provided, route_id must also be provided.
{% enddocs %}

{% docs rt_entity_selector__route_type %}
The route_type from the GTFS that this selector refers to.
{% enddocs %}

{% docs rt_entity_selector__direction_id %}
The direction_id from the GTFS feed trips.txt file, used to select all trips in one direction for a route, specified by route_id. If direction_id is provided, route_id must also be provided.

Caution: this field is still experimental, and subject to change. It may be formally adopted in the future.
{% enddocs %}

{% docs rt_entity_selector__trip %}
The trip instance from the GTFS that this selector refers to. This TripDescriptor must resolve to a single trip instance in the GTFS data (e.g., a producer cannot provide only a trip_id for exact_times=0 trips). If the ScheduleRelationship field is populated within this TripDescriptor it will be ignored by consumers when attempting to identify the GTFS trip.
{% enddocs %}

{% docs rt_entity_selector__stop_id %}
The stop_id from the GTFS feed that this selector refers to.
{% enddocs %}
