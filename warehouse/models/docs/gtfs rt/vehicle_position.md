Original definitions from https://gtfs.org/realtime/reference/#message-vehicleposition

{% docs gtfs_vehicle_position__current_stop_sequence %}
The stop sequence index of the current stop. The meaning of current_stop_sequence (i.e., the stop that it refers to) is determined by current_status. If current_status is missing IN_TRANSIT_TO is assumed.
{% enddocs %}

{% docs gtfs_vehicle_position__stop_id %}
Identifies the current stop. The value must be the same as in stops.txt in the corresponding GTFS feed. If StopTimeProperties.assigned_stop_id is used to assign a stop_id, this field should also reflect the change in stop_id.
{% enddocs %}

{% docs gtfs_vehicle_position__current_status %}
The exact status of the vehicle with respect to the current stop. Ignored if current_stop_sequence is missing.
{% enddocs %}

{% docs gtfs_vehicle_position__timestamp %}
Moment at which the vehicle's position was measured. In POSIX time (i.e., number of seconds since January 1st 1970 00:00:00 UTC).
Field has been converted to TIMESTAMP type for convenience.
{% enddocs %}

{% docs gtfs_vehicle_position__congestion_level %}
Congestion level that is affecting this vehicle.
Values: UNKNOWN_CONGESTION_LEVEL, RUNNING_SMOOTHLY, STOP_AND_GO, CONGESTION, SEVERE_CONGESTION
{% enddocs %}

{% docs gtfs_vehicle_position__occupancy_status %}
The state of passenger occupancy for the vehicle or carriage. If multi_carriage_details is populated with per-carriage OccupancyStatus, then this field should describe the entire vehicle with all carriages accepting passengers considered.
Caution: this field is still experimental, and subject to change. It may be formally adopted in the future.
{% enddocs %}

{% docs gtfs_vehicle_position__occupancy_percentage %}
A percentage value indicating the degree of passenger occupancy in the vehicle. The value 100 should represent the total maximum occupancy the vehicle was designed for, including both seating and standing capacity, and current operating regulations allow. The value may exceed 100 if there are more passengers than the maximum designed capacity. The precision of occupancy_percentage should be low enough that individual passengers cannot be tracked boarding or alighting the vehicle. If multi_carriage_details is populated with per-carriage occupancy_percentage, then this field should describe the entire vehicle with all carriages accepting passengers considered.
Caution: this field is still experimental, and subject to change. It may be formally adopted in the future.
{% enddocs %}
