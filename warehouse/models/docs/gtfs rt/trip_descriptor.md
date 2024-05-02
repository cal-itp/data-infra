Original definitions from https://gtfs.org/realtime/reference/#message-tripdescriptor

{% docs gtfs_trip_descriptor__trip_id %}
The trip_id from the GTFS feed that this selector refers to. For non frequency-based trips (trips not defined in GTFS frequencies.txt), this field is enough to uniquely identify the trip. For frequency-based trips defined in GTFS frequencies.txt, trip_id, start_time, and start_date are all required. For scheduled-based trips (trips not defined in GTFS frequencies.txt), trip_id can only be omitted if the trip can be uniquely identified by a combination of route_id, direction_id, start_time, and start_date, and all those fields are provided. When schedule_relationship is DUPLICATED within a TripUpdate, the trip_id identifies the trip from static GTFS to be duplicated. When schedule_relationship is DUPLICATED within a VehiclePosition, the trip_id identifies the new duplicate trip and must contain the value for the corresponding TripUpdate.TripProperties.trip_id.
{% enddocs %}

{% docs gtfs_trip_descriptor__route_id %}
The route_id from the GTFS that this selector refers to. If trip_id is omitted, route_id, direction_id, start_time, and schedule_relationship=SCHEDULED must all be set to identify a trip instance. TripDescriptor.route_id should not be used within an Alert EntitySelector to specify a route-wide alert that affects all trips for a route - use EntitySelector.route_id instead.
{% enddocs %}

{% docs gtfs_trip_descriptor__direction_id %}
The direction_id from the GTFS feed trips.txt file, indicating the direction of travel for trips this selector refers to. If trip_id is omitted, direction_id must be provided.
Caution: this field is still experimental, and subject to change. It may be formally adopted in the future.
{% enddocs %}

{% docs gtfs_trip_descriptor__start_time %}
Initially scheduled start time for a trip instance. For non-frequency-based trips, this field can be omitted or must match the GTFS feed. For frequency-based trips (defined in GTFS frequencies.txt), start_time is mandatory in trip updates and vehicle positions. If exact_times=1 in GTFS, start_time must be a multiple of headway_secs after the frequencies.txt start_time. If exact_times=0, the initial start_time is arbitrary but should then be considered fixed (updates reflected in StopTimeUpdate). Omitting trip_id requires providing start_time.  Use the same format as in GTFS frequencies.txt (e.g., 11:15:35).
{% enddocs %}
      
{% docs gtfs_trip_descriptor__start_date %}
The start date of this trip instance in YYYYMMDD format. For scheduled trips (trips not defined in GTFS frequencies.txt), this field must be provided to disambiguate trips that are so late as to collide with a scheduled trip on a next day. For example, for a train that departs 8:00 and 20:00 every day, and is 12 hours late, there would be two distinct trips on the same time. This field can be provided but is not mandatory for schedules in which such collisions are impossible - for example, a service running on hourly schedule where a vehicle that is one hour late is not considered to be related to schedule anymore. This field is required for frequency-based trips defined in GTFS frequencies.txt. If trip_id is omitted, start_date must be provided.
{% enddocs %}

{% docs gtfs_trip_descriptor__schedule_relationship %}
The relation between this trip and the static schedule. If TripDescriptor is provided in an Alert EntitySelector, the schedule_relationship field is ignored by consumers when identifying the matching trip instance.
{% enddocs %}
