Original field definitions provided in https://gtfs.org/reference/static#stop_timestxt
These are aggregated columns providing the counts of instances of various enum values

{% docs column_num_regularly_scheduled_pickup_stop_events %}
Count of stop events on this trip where `pickup_type` is null or 0, indicating a regularly scheduled pickups at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_no_pickup_stop_events %}
Count of stop events on this trip where `pickup_type` is 1, indicating no pickups at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_phone_call_required_for_pickup_stop_events %}
Count of stop events on this trip where `pickup_type` is 1, indicating that a phone call is required to arrange a pickup at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_coordinate_pickup_with_driver_stop_events %}
Count of stop events on this trip where `pickup_type` is 3, indicating that coordination with the driver is required to arrange a pickup at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_regularly_scheduled_drop_off_stop_events %}
Count of stop events on this trip where `drop_off_type` is null or 0, indicating a regularly scheduled drop offs at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_no_drop_off_stop_events %}
Count of stop events on this trip where `drop_off_type` is 1, indicating no drop offs at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_phone_call_required_for_drop_off_stop_events %}
Count of stop events on this trip where `drop_off_type` is 1, indicating that a phone call is required to arrange a drop off at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_coordinate_drop_off_with_driver_stop_events %}
Count of stop events on this trip where `drop_off_type` is 3, indicating that coordination with the driver is required to arrange a drop off at the given stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_continuous_pickup_stop_events %}
Count of stop events on this trip where `continuous_pickup` is 0, indicating continuous stopping pickups between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_no_continuous_pickup_stop_events %}
Count of stop events on this trip where `continuous_pickup` is null or 1, indicating that there is no continuous stopping pickup behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_phone_call_required_for_continuous_pickup_stop_events %}
Count of stop events on this trip where `continuous_pickup` is 2, indicating that a phone call to the agency is required to arrange continuous pickup behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_coordinate_continuous_pickup_with_driver_stop_events %}
Count of stop events on this trip where `continuous_pickup` is 3, indicating that coordination with the driver is required to arrange continuous pickup behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_continuous_drop_off_stop_events %}
Count of stop events on this trip where `continuous_drop_off` is 0, indicating continuous stopping drop offs between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_no_continuous_drop_off_stop_events %}
Count of stop events on this trip where `continuous_drop_off` is null or 1, indicating that there is no continuous stopping drop off behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_phone_call_required_for_continuous_drop_off_stop_events %}
Count of stop events on this trip where `continuous_drop_off` is 2, indicating that a phone call to the agency is required to arrange continuous drop off behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_coordinate_continuous_drop_off_with_driver_stop_events %}
Count of stop events on this trip where `continuous_drop_off` is 3, indicating that coordination with the driver is required to arrange continuous drop off behavior between the given stops and their respective subsequent stops.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_approximate_timepoint_stop_events %}
Count of stop events on this trip where `timepoint` is 0, indicating approximate stop arrival/departure times.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_exact_timepoint_stop_events %}
Count of stop events on this trip where `timepoint` is null or 1, indicating exact stop arrival/departure times.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_arrival_times_populated_stop_events %}
Count of stop events on this trip where `arrival_time` is populated.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}

{% docs column_num_departure_times_populated_stop_events %}
Count of stop events on this trip where `departure_time` is populated.

See https://gtfs.org/reference/static#stop_timestxt for the raw data definitions.
{% enddocs %}
