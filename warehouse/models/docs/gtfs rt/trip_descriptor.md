Original definitions from https://gtfs.org/realtime/reference/#message-tripdescriptor

{% docs rt_trip_descriptor__trip_id %}
The trip_id from the GTFS feed that this selector refers to. For non frequency-based trips (trips not defined in GTFS frequencies.txt), this field is enough to uniquely identify the trip. For frequency-based trips defined in GTFS frequencies.txt, trip_id, start_time, and start_date are all required. For scheduled-based trips (trips not defined in GTFS frequencies.txt), trip_id can only be omitted if the trip can be uniquely identified by a combination of route_id, direction_id, start_time, and start_date, and all those fields are provided. When schedule_relationship is DUPLICATED within a TripUpdate, the trip_id identifies the trip from static GTFS to be duplicated. When schedule_relationship is DUPLICATED within a VehiclePosition, the trip_id identifies the new duplicate trip and must contain the value for the corresponding TripUpdate.TripProperties.trip_id.
{% enddocs %}

{% docs rt_trip_descriptor__route_id %}
The route_id from the GTFS that this selector refers to. If trip_id is omitted, route_id, direction_id, start_time, and schedule_relationship=SCHEDULED must all be set to identify a trip instance. TripDescriptor.route_id should not be used within an Alert EntitySelector to specify a route-wide alert that affects all trips for a route - use EntitySelector.route_id instead.
{% enddocs %}

{% docs rt_trip_descriptor__direction_id %}
The direction_id from the GTFS feed trips.txt file, indicating the direction of travel for trips this selector refers to. If trip_id is omitted, direction_id must be provided.
Caution: this field is still experimental, and subject to change. It may be formally adopted in the future.
{% enddocs %}

{% docs rt_trip_descriptor__start_time %}
The initially scheduled start time of this trip instance. When the trip_id corresponds to a non-frequency-based trip, this field should either be omitted or be equal to the value in the GTFS feed. When the trip_id correponds to a frequency-based trip defined in GTFS frequencies.txt, start_time is required and must be specified for trip updates and vehicle positions. If the trip corresponds to exact_times=1 GTFS record, then start_time must be some multiple (including zero) of headway_secs later than frequencies.txt start_time for the corresponding time period. If the trip corresponds to exact_times=0, then its start_time may be arbitrary, and is initially expected to be the first departure of the trip. Once established, the start_time of this frequency-based exact_times=0 trip should be considered immutable, even if the first departure time changes -- that time change may instead be reflected in a StopTimeUpdate. If trip_id is omitted, start_time must be provided. Format and semantics of the field is same as that of GTFS frequencies.txt start_time, e.g., 11:15:35 or 25:15:35.
{% enddocs %}
      
{% docs rt_trip_descriptor__start_date %}
The start date of this trip instance in YYYYMMDD format. For scheduled trips (trips not defined in GTFS frequencies.txt), this field must be provided to disambiguate trips that are so late as to collide with a scheduled trip on a next day. For example, for a train that departs 8:00 and 20:00 every day, and is 12 hours late, there would be two distinct trips on the same time. This field can be provided but is not mandatory for schedules in which such collisions are impossible - for example, a service running on hourly schedule where a vehicle that is one hour late is not considered to be related to schedule anymore. This field is required for frequency-based trips defined in GTFS frequencies.txt. If trip_id is omitted, start_date must be provided.
{% enddocs %}

{% docs rt_trip_descriptor__schedule_relationship %}
The relation between this trip and the static schedule. If TripDescriptor is provided in an Alert EntitySelector, the schedule_relationship field is ignored by consumers when identifying the matching trip instance.
{% enddocs %}
